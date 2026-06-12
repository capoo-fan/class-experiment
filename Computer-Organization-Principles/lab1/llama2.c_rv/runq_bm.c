#define C_TEST

/* Inference for Llama-2 Transformer model in pure C with INT8 quantization */

#ifdef C_TEST
#include <time.h>
#else
#include "peripheral.h"
#endif
#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <math.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include "stories260K_bin.h"
#include "tokenizer_bin.h"


// ----------------------------------------------------------------------------
// Transformer model

typedef struct {
    int dim; // transformer dimension
    int hidden_dim; // for ffn layers
    int n_layers; // number of layers
    int n_heads; // number of query heads
    int n_kv_heads; // number of key/value heads (can be < query heads because of multiquery)
    int vocab_size; // vocabulary size, usually 256 (byte-level)
    int seq_len; // max sequence length
} Config;

typedef struct {
    // token embedding table
    int8_t* token_embedding_table;    // (vocab_size, dim)
    // weights for rmsnorms
    int8_t* rms_att_weight; // (layer, dim) rmsnorm weights
    int8_t* rms_ffn_weight; // (layer, dim)
    // weights for matmuls. note dim == n_heads * head_size
    int8_t* wq; // (layer, dim, n_heads * head_size)
    int8_t* wk; // (layer, dim, n_kv_heads * head_size)
    int8_t* wv; // (layer, dim, n_kv_heads * head_size)
    int8_t* wo; // (layer, n_heads * head_size, dim)
    // weights for ffn
    int8_t* w1; // (layer, hidden_dim, dim)
    int8_t* w2; // (layer, dim, hidden_dim)
    int8_t* w3; // (layer, hidden_dim, dim)
    // final rmsnorm
    int8_t* rms_final_weight; // (dim,)
    // (optional) classifier weights for the logits, on the last layer
    int8_t* wcls;
    // scales for quantization
    float scale_token_embedding;
    float* scale_rms_att;
    float* scale_rms_ffn;
    float* scale_wq;
    float* scale_wk;
    float* scale_wv;
    float* scale_wo;
    float* scale_w1;
    float* scale_w2;
    float* scale_w3;
    float scale_rms_final;
    float scale_wcls;
} TransformerWeights;

typedef struct {
    // current wave of activations
    float *x; // activation at current time stamp (dim,)
    float *xb; // same, but inside a residual branch (dim,)
    float *xb2; // an additional buffer just for convenience (dim,)
    float *hb; // buffer for hidden dimension in the ffn (hidden_dim,)
    float *hb2; // buffer for hidden dimension in the ffn (hidden_dim,)
    float *q; // query (dim,)
    float *k; // key (dim,)
    float *v; // value (dim,)
    float *att; // buffer for scores/attention values (n_heads, seq_len)
    float *logits; // output logits
    // kv cache
    float* key_cache;   // (layer, seq_len, dim)
    float* value_cache; // (layer, seq_len, dim)
    // quantized activations
    int8_t *xq; // (dim,)
    int8_t *hq; // (hidden_dim,)
} RunState;

typedef struct {
    Config config; // the hyperparameters of the architecture (the blueprint)
    TransformerWeights weights; // the weights of the model
    RunState state; // buffers for the "wave" of activations in the forward pass
    // some more state needed to properly clean up the memory mapping (sigh)
    int fd; // file descriptor for memory mapping
    float* data; // memory mapped data pointer
    ssize_t file_size; // size of the checkpoint file in bytes
} Transformer;

void malloc_run_state(RunState* s, Config* p) {
    // we calloc instead of malloc to keep valgrind happy
    int kv_dim = (p->dim * p->n_kv_heads) / p->n_heads;
    s->x = (float*)malloc(p->dim * sizeof(float));
    s->xb = (float*)malloc(p->dim * sizeof(float));
    s->xb2 = (float*)malloc(p->dim * sizeof(float));
    s->hb = (float*)malloc(p->hidden_dim * sizeof(float));
    s->hb2 = (float*)malloc(p->hidden_dim * sizeof(float));
    s->q = (float*)malloc(p->dim * sizeof(float));
    s->key_cache = (float*)malloc(p->n_layers * p->seq_len * kv_dim * sizeof(float));
    s->value_cache = (float*)malloc(p->n_layers * p->seq_len * kv_dim * sizeof(float));
    s->att = (float*)malloc(p->n_heads * p->seq_len * sizeof(float));
    s->logits = (float*)malloc(p->vocab_size * sizeof(float));
    s->xq = (int8_t*)malloc(p->dim * sizeof(int8_t));
    s->hq = (int8_t*)malloc(p->hidden_dim * sizeof(int8_t));

    // ensure all mallocs went fine
    if (!s->x || !s->xb || !s->xb2 || !s->hb || !s->hb2 || !s->q
     || !s->key_cache || !s->value_cache || !s->att || !s->logits
     || !s->xq || !s->hq) {
#ifdef C_TEST
        fprintf(stderr, "malloc failed!\n");
        exit(EXIT_FAILURE);
#else
        printf("malloc_run_state failed!\n");
#endif
    }

    if (!s->x) printf("s->x failed\n");
    if (!s->xb) printf("s->xb failed\n");
    if (!s->xb2) printf("s->xb2 failed\n");
    if (!s->hb) printf("s->hb failed\n");
    if (!s->hb2) printf("s->hb2 failed\n");
    if (!s->q) printf("s->q failed\n");
    if (!s->key_cache) printf("s->key_cache failed\n");
    if (!s->value_cache) printf("s->value_cache failed\n");
    if (!s->att) printf("s->att failed\n");
    if (!s->logits) printf("s->logits failed\n");
    if (!s->xq) printf("s->xq failed\n");
    if (!s->hq) printf("s->hq failed\n");

    for (int i = 0; i < p->dim; i++) {
        s->x[i] = 0.0;
        s->xb[i] = 0.0;
        s->xb2[i] = 0.0;
        s->q[i] = 0.0;
        s->xq[i] = 0;
    }
    for (int i = 0; i < p->hidden_dim; i++) {
        s->hb[i] = 0.0;
        s->hb2[i] = 0.0;
        s->hq[i] = 0;
    }
    for (int i = 0; i < p->n_layers * p->seq_len * kv_dim; i++) {
        s->key_cache[i] = 0.0;
        s->value_cache[i] = 0.0;
    }
    for (int i = 0; i < p->n_heads * p->seq_len; i++) s->att[i] = 0.0;
    for (int i = 0; i < p->vocab_size; i++) s->logits[i] = 0.0;
}

void free_run_state(RunState* s) {
    free(s->x);
    free(s->xb);
    free(s->xb2);
    free(s->hb);
    free(s->hb2);
    free(s->q);
    free(s->att);
    free(s->logits);
    free(s->key_cache);
    free(s->value_cache);
    free(s->xq);
    free(s->hq);
}

void quantize_int8(int8_t* q, float* f, int size, float* scale_out) {
    float max_abs = 0.0f;
    for (int i = 0; i < size; i++) {
        max_abs = fmax(max_abs, fabsf(f[i]));
    }
    *scale_out = max_abs > 0.0f ? max_abs / 127.0f : 1.0f;
    for (int i = 0; i < size; i++) {
        float val = f[i] / *scale_out;
        q[i] = (int8_t) roundf(val);
        if (q[i] > 127) q[i] = 127;
        if (q[i] < -127) q[i] = -127;
    }
}

void memory_map_weights(TransformerWeights *w, Config* p, float* ptr, int shared_weights) {
    int head_size = p->dim / p->n_heads;
    // make sure the multiplications below are done in 64bit to fit the parameter counts of 13B+ models
    unsigned long long n_layers = p->n_layers;
    unsigned long long i;

    // token_embedding_table
    w->scale_token_embedding = w_scale_token_embedding;
    w->token_embedding_table = w_token_embedding_table;
    ptr += p->vocab_size * p->dim;

    // rms_att_weight
    w->scale_rms_att = w_scale_rms_att;
    w->rms_att_weight = w_rms_att_weight;
    ptr += n_layers * p->dim;

    // wq
    int out_dim = p->n_heads * head_size;
    unsigned long long layer_size = (unsigned long long)p->dim * out_dim;
    w->scale_wq = w_scale_wq;
    w->wq = w_wq;
    ptr += n_layers * layer_size;

    // wk
    int kv_dim = p->n_kv_heads * head_size;
    layer_size = (unsigned long long)p->dim * kv_dim;
    w->scale_wk = w_scale_wk;
    w->wk = w_wk;
    ptr += n_layers * layer_size;

    // wv
    kv_dim = p->n_kv_heads * head_size;
    layer_size = (unsigned long long)p->dim * kv_dim;
    w->scale_wv = w_scale_wv;
    w->wv = w_wv;
    ptr += n_layers * layer_size;

    // wo
    int in_dim = p->n_heads * head_size;
    layer_size = (unsigned long long)in_dim * p->dim;
    w->scale_wo = w_scale_wo;
    w->wo = w_wo;
    ptr += n_layers * layer_size;

    // rms_ffn_weight
    w->scale_rms_ffn = w_scale_rms_ffn;
    w->rms_ffn_weight = w_rms_ffn_weight;
    ptr += n_layers * p->dim;

    // w1
    layer_size = (unsigned long long)p->dim * p->hidden_dim;
    w->scale_w1 = w_scale_w1;
    w->w1 = w_w1;
    ptr += n_layers * layer_size;

    // w2
    layer_size = (unsigned long long)p->hidden_dim * p->dim;
    w->scale_w2 = w_scale_w2;
    w->w2 = w_w2;
    ptr += n_layers * layer_size;

    // w3
    layer_size = (unsigned long long)p->dim * p->hidden_dim;
    w->scale_w3 = w_scale_w3;
    w->w3 = w_w3;
    ptr += n_layers * layer_size;

    // rms_final_weight
    w->scale_rms_final = w_scale_rms_final;
    w->rms_final_weight = w_rms_final_weight;
    ptr += p->dim;

    ptr += p->seq_len * head_size / 2; // skip what used to be freq_cis_real (for RoPE)
    ptr += p->seq_len * head_size / 2; // skip what used to be freq_cis_imag (for RoPE)

    // wcls
    if (shared_weights) {
        w->wcls = w->token_embedding_table;
        w->scale_wcls = w->scale_token_embedding;
    } else {
        w->scale_wcls = w_scale_wcls;
        w->wcls = w_wcls;
    }
}

void read_checkpoint(/*char* checkpoint,*/ Config* config, TransformerWeights* weights,
                     int* fd, float** data, ssize_t* file_size) {
    config->dim        = checkpoint_config[0]; // transformer dimension
    config->hidden_dim = checkpoint_config[1]; // for ffn layers
    config->n_layers   = checkpoint_config[2]; // number of layers
    config->n_heads    = checkpoint_config[3]; // number of query heads
    config->n_kv_heads = checkpoint_config[4]; // number of key/value heads (can be < query heads because of multiquery)
    config->vocab_size = checkpoint_config[5]; // vocabulary size, usually 256 (byte-level)
    config->seq_len    = checkpoint_config[6]; // max sequence length

    // negative vocab size is hacky way of signaling unshared weights. bit yikes.
    int shared_weights = config->vocab_size > 0 ? 1 : 0;
    config->vocab_size = abs(config->vocab_size);
   
    float* weights_ptr = *data + sizeof(Config)/sizeof(float);
    memory_map_weights(weights, config, weights_ptr, shared_weights);
}

void build_transformer(Transformer *t/*, char* checkpoint_path*/) {
    // read in the Config and the Weights from the checkpoint
    read_checkpoint(/*checkpoint_path,*/ &t->config, &t->weights, &t->fd, &t->data, &t->file_size);

    // allocate the RunState buffers
    malloc_run_state(&t->state, &t->config);
}

void free_transformer(Transformer* t) {
    free_run_state(&t->state);
}

// ----------------------------------------------------------------------------
// neural net blocks; the dynamics of the Transformer

void rmsnorm(float* o, float* x, int8_t* weight, float scale, int size) {
    // calculate sum of squares
    float ss = 0.0f;
    for (int j = 0; j < size; j++) {
        ss += x[j] * x[j];
    }
    ss /= size;
    ss += 1e-5f;
    ss = 1.0f / sqrtf(ss);
    // normalize and scale
    for (int j = 0; j < size; j++) {
        o[j] = ((float)weight[j]) * scale * (ss * x[j]);
    }
}

void softmax(float* x, int size) {
    // find max value (for numerical stability)
    float max_val = x[0];
    for (int i = 1; i < size; i++) {
        if (x[i] > max_val) {
            max_val = x[i];
        }
    }
    // exp and sum
    float sum = 0.0f;
    for (int i = 0; i < size; i++) {
        x[i] = expf(x[i] - max_val);
        sum += x[i];
    }
    // normalize
    for (int i = 0; i < size; i++) {
        x[i] /= sum;
    }
}

void matmul_int8(float* xout, int8_t* xq, float scale_x, int8_t* w, float scale_w, int n, int d) {
    // W (d,n) @ x (n,) -> xout (d,)
    // quantized version using int8 operations
    int i;
    #pragma omp parallel for private(i)
    for (i = 0; i < d; i++) {
        int32_t val = 0;
        for (int j = 0; j < n; j++) {
            val += ((int32_t)w[i * n + j]) * ((int32_t)xq[j]);
        }
        xout[i] = ((float)val) * scale_w * scale_x;
    }
}

float* forward(Transformer* transformer, int token, int pos) {

    // a few convenience variables
    Config* p = &transformer->config;
    TransformerWeights* w = &transformer->weights;
    RunState* s = &transformer->state;
    float *x = s->x;
    int dim = p->dim;
    int kv_dim = (p->dim * p->n_kv_heads) / p->n_heads;
    int kv_mul = p->n_heads / p->n_kv_heads; // integer multiplier of the kv sharing in multiquery
    int hidden_dim =  p->hidden_dim;
    int head_size = dim / p->n_heads;

    // copy the token embedding into x
    int8_t* content_row = w->token_embedding_table + token * dim;
    for (int i = 0; i < dim; i++) {
        x[i] = ((float)content_row[i]) * w->scale_token_embedding;
    }

    // forward all the layers
    for(unsigned long long l = 0; l < p->n_layers; l++) {

        // attention rmsnorm
        rmsnorm(s->xb, x, w->rms_att_weight + l*dim, w->scale_rms_att[l], dim);

        // quantize xb for qkv matmuls
        float scale_qkv = 0.0f;
        quantize_int8(s->xq, s->xb, dim, &scale_qkv);

        // key and value point to the kv cache
        int loff = l * p->seq_len * kv_dim; // kv cache layer offset for convenience
        s->k = s->key_cache + loff + pos * kv_dim;
        s->v = s->value_cache + loff + pos * kv_dim;

        // qkv matmuls for this position
        matmul_int8(s->q, s->xq, scale_qkv, w->wq + l*dim*dim, w->scale_wq[l], dim, dim);
        matmul_int8(s->k, s->xq, scale_qkv, w->wk + l*dim*kv_dim, w->scale_wk[l], dim, kv_dim);
        matmul_int8(s->v, s->xq, scale_qkv, w->wv + l*dim*kv_dim, w->scale_wv[l], dim, kv_dim);

        // RoPE relative positional encoding: complex-valued rotate q and k in each head
        for (int i = 0; i < dim; i+=2) {
            int head_dim = i % head_size;
            float freq = 1.0f / powf(10000.0f, head_dim / (float)head_size);
            float val = pos * freq;
            float fcr = cosf(val);
            float fci = sinf(val);
            int rotn = i < kv_dim ? 2 : 1; // how many vectors? 2 = q & k, 1 = q only
            for (int v = 0; v < rotn; v++) {
                float* vec = v == 0 ? s->q : s->k; // the vector to rotate (query or key)
                float v0 = vec[i];
                float v1 = vec[i+1];
                vec[i]   = v0 * fcr - v1 * fci;
                vec[i+1] = v0 * fci + v1 * fcr;
            }
        }

        // multihead attention. iterate over all heads
        int h;
        #pragma omp parallel for private(h)
        for (h = 0; h < p->n_heads; h++) {
            // get the query vector for this head
            float* q = s->q + h * head_size;
            // attention scores for this head
            float* att = s->att + h * p->seq_len;
            // iterate over all timesteps, including the current one
            for (int t = 0; t <= pos; t++) {
                // get the key vector for this head and at this timestep
                float* k = s->key_cache + loff + t * kv_dim + (h / kv_mul) * head_size;
                // calculate the attention score as the dot product of q and k
                float score = 0.0f;
                for (int i = 0; i < head_size; i++) {
                    score += q[i] * k[i];
                }
                score /= sqrtf(head_size);
                // save the score to the attention buffer
                att[t] = score;
            }

            // softmax the scores to get attention weights, from 0..pos inclusively
            softmax(att, pos + 1);

            // weighted sum of the values, store back into xb
            float* xb = s->xb + h * head_size;
            memset(xb, 0, head_size * sizeof(float));
            for (int t = 0; t <= pos; t++) {
                // get the value vector for this head and at this timestep
                float* v = s->value_cache + loff + t * kv_dim + (h / kv_mul) * head_size;
                // get the attention weight for this timestep
                float a = att[t];
                // accumulate the weighted value into xb
                for (int i = 0; i < head_size; i++) {
                    xb[i] += a * v[i];
                }
            }
        }

        // quantize xb for wo matmul
        float scale_o = 0.0f;
        quantize_int8(s->xq, s->xb, dim, &scale_o);

        // final matmul to get the output of the attention
        matmul_int8(s->xb2, s->xq, scale_o, w->wo + l*dim*dim, w->scale_wo[l], dim, dim);

        // residual connection back into x
        for (int i = 0; i < dim; i++) {
            x[i] += s->xb2[i];
        }

        // ffn rmsnorm
        rmsnorm(s->xb, x, w->rms_ffn_weight + l*dim, w->scale_rms_ffn[l], dim);

        // quantize xb for w1 and w3 matmuls
        float scale_ffn = 0.0f;
        quantize_int8(s->xq, s->xb, dim, &scale_ffn);

        // Now for FFN in PyTorch we have: self.w2(F.silu(self.w1(x)) * self.w3(x))
        // first calculate self.w1(x) and self.w3(x)
        matmul_int8(s->hb, s->xq, scale_ffn, w->w1 + l*dim*hidden_dim, w->scale_w1[l], dim, hidden_dim);
        matmul_int8(s->hb2, s->xq, scale_ffn, w->w3 + l*dim*hidden_dim, w->scale_w3[l], dim, hidden_dim);

        // SwiGLU non-linearity
        for (int i = 0; i < hidden_dim; i++) {
            float val = s->hb[i];
            // silu(x)=x*σ(x), where σ(x) is the logistic sigmoid
            val *= (1.0f / (1.0f + expf(-val)));
            // elementwise multiply with w3(x)
            val *= s->hb2[i];
            s->hb[i] = val;
        }

        // quantize hb for w2 matmul
        float scale_h = 0.0f;
        quantize_int8(s->hq, s->hb, hidden_dim, &scale_h);

        // final matmul to get the output of the ffn
        matmul_int8(s->xb, s->hq, scale_h, w->w2 + l*hidden_dim*dim, w->scale_w2[l], hidden_dim, dim);

        // residual connection
        for (int i = 0; i < dim; i++) {
            x[i] += s->xb[i];
        }
    }

    // final rmsnorm
    rmsnorm(x, x, w->rms_final_weight, w->scale_rms_final, dim);

    // quantize x for classifier matmul
    float scale_final = 0.0f;
    quantize_int8(s->xq, x, dim, &scale_final);

    // classifier into logits
    matmul_int8(s->logits, s->xq, scale_final, w->wcls, w->scale_wcls, p->dim, p->vocab_size);
    return s->logits;
}

// ----------------------------------------------------------------------------
// The Byte Pair Encoding (BPE) Tokenizer that translates strings <-> tokens

typedef struct {
    char *str;
    int id;
} TokenIndex;

typedef struct {
    char** vocab;
    float* vocab_scores;
    TokenIndex *sorted_vocab;
    int vocab_size;
    unsigned int max_token_length;
    unsigned char byte_pieces[512]; // stores all single-byte strings
} Tokenizer;

int compare_tokens(const void *a, const void *b) {
    return strcmp(((TokenIndex*)a)->str, ((TokenIndex*)b)->str);
}

void build_tokenizer(Tokenizer* t, /*char* tokenizer_path,*/ int vocab_size) {
    // i should have written the vocab_size into the tokenizer file... sigh
    t->vocab_size = vocab_size;
    // malloc space to hold the scores and the strings
    t->vocab = (char**)malloc(vocab_size * sizeof(char*));
    t->vocab_scores = (float*)malloc(vocab_size * sizeof(float));
    t->sorted_vocab = NULL; // initialized lazily
    for (int i = 0; i < 256; i++) {
        t->byte_pieces[i * 2] = (unsigned char)i;
        t->byte_pieces[i * 2 + 1] = '\0';
    }
    
    t->max_token_length = tokenizer_max_token_length;

    for (int i = 0; i < vocab_size; i++) {       
        *(t->vocab_scores + i) = tokenizer_vocab_scores[i];
        t->vocab[i] = (char *)malloc(tokenizer_len[i] + 1);
        strcpy(t->vocab[i], tokenizer_vocab[i]);
    }
}

void free_tokenizer(Tokenizer* t) {
    for (int i = 0; i < t->vocab_size; i++) { free(t->vocab[i]); }
    free(t->vocab);
    free(t->vocab_scores);
    free(t->sorted_vocab);
}

char* decode(Tokenizer* t, int prev_token, int token) {
    char *piece = t->vocab[token];
    // following BOS (1) token, sentencepiece decoder strips any leading whitespace (see PR #89)
    if (prev_token == 1 && piece[0] == ' ') { piece++; }
    // careful, some tokens designate raw bytes, and look like e.g. '<0x01>'
    // parse this and convert and return the actual byte
    unsigned char byte_val;
    if (sscanf(piece, "<0x%02hhX>", &byte_val) == 1) {
        piece = (char*)t->byte_pieces + byte_val * 2;
    }
    return piece;
}

void safe_printf(char *piece) {
    // piece might be a raw byte token, and we only want to print printable chars or whitespace
    // because some of the other bytes can be various control codes, backspace, etc.
    if (piece == NULL) { return; }
    if (piece[0] == '\0') { return; }
    if (piece[1] == '\0') {
        unsigned char byte_val = piece[0];
        if (!(isprint(byte_val) || isspace(byte_val))) {
            return; // bad byte, don't print it
        }
    }
    printf("%s", piece);
}

int str_lookup(char *str, TokenIndex *sorted_vocab, int vocab_size) {
    // efficiently find the perfect match for str in vocab, return its index or -1 if not found
    TokenIndex tok = { .str = str }; // acts as the key to search for
    TokenIndex *res = bsearch(&tok, sorted_vocab, vocab_size, sizeof(TokenIndex), compare_tokens);
    return res != NULL ? res->id : -1;
}

void encode(Tokenizer* t, char *text, int8_t bos, int8_t eos, int *tokens, int *n_tokens) {
    // encode the string text (input) into an upper-bound preallocated tokens[] array
    // bos != 0 means prepend the BOS token (=1), eos != 0 means append the EOS token (=2)
#ifdef C_TEST
    if (text == NULL) { fprintf(stderr, "cannot encode NULL text\n"); exit(EXIT_FAILURE); }
#else
    if (text == 0) printf("cannot encode NULL text\n");
#endif

    if (t->sorted_vocab == NULL) {
        // lazily malloc and sort the vocabulary
        t->sorted_vocab = malloc(t->vocab_size * sizeof(TokenIndex));
        for (int i = 0; i < t->vocab_size; i++) {
            t->sorted_vocab[i].str = t->vocab[i];
            t->sorted_vocab[i].id = i;
        }
        qsort(t->sorted_vocab, t->vocab_size, sizeof(TokenIndex), compare_tokens);
    }

    // create a temporary buffer that will store merge candidates of always two consecutive tokens
    // *2 for concat, +1 for null terminator +2 for UTF8 (in case max_token_length is 1)
    char* str_buffer = malloc((t->max_token_length*2 +1 +2) * sizeof(char));
    size_t str_len = 0;

    // start at 0 tokens
    *n_tokens = 0;

    // add optional BOS (=1) token, if desired
    if (bos) tokens[(*n_tokens)++] = 1;

    // add_dummy_prefix is true by default
    // so prepend a dummy prefix token to the input string, but only if text != ""
    if (text[0] != '\0') {
        int dummy_prefix = str_lookup(" ", t->sorted_vocab, t->vocab_size);
        tokens[(*n_tokens)++] = dummy_prefix;
    }

    // Okay UTF-8 time. This will get messy. Here is the reference from Wikipedia:
    // Code point ↔ UTF-8 conversion
    // First code point	Last code point	Byte 1	Byte 2	Byte 3	Byte 4
    // U+0000	U+007F	    0xxxxxxx
    // U+0080	U+07FF	    110xxxxx	10xxxxxx
    // U+0800	U+FFFF	    1110xxxx	10xxxxxx	10xxxxxx
    // U+10000	U+10FFFF    11110xxx	10xxxxxx	10xxxxxx	10xxxxxx

    // process the raw (UTF-8) byte sequence of the input string
    for (char *c = text; *c != '\0'; c++) {

        // reset buffer if the current byte is ASCII or a leading byte
        // 0xC0 is 11000000, so (*c & 0xC0) keeps the first 2 bits and zeros the rest
        // 0x80 is 10000000
        // in UTF-8, all continuation bytes start with "10" in first two bits
        // so in English this is: "if this byte is not a continuation byte"
        if ((*c & 0xC0) != 0x80) {
            // this byte must be either a leading byte (11...) or an ASCII char (0x...)
            // => reset our location, as we're starting a new UTF-8 codepoint
            str_len = 0;
        }

        // append the current byte to the buffer
        str_buffer[str_len++] = *c; // ++ is post-increment, incremented after this line
        str_buffer[str_len] = '\0';

        // while the next character is a continuation byte, continue appending
        // but if there are too many of them, just stop to avoid overruning str_buffer size.
        if ((*(c+1) & 0xC0) == 0x80 && str_len < 4) {
            continue;
        }

        // ok c+1 is not a continuation byte, so we've read in a full codepoint
        int id = str_lookup(str_buffer, t->sorted_vocab, t->vocab_size);

        if (id != -1) {
            // we found this codepoint in vocab, add it as a token
            tokens[(*n_tokens)++] = id;
        } else {
            // byte_fallback encoding: just encode each byte as a token
            // +3 is here because the first 3 vocab elements are <unk>, <s>, </s>
            // so the individual bytes only start at index 3
            for (int i=0; i < str_len; i++) {
                tokens[(*n_tokens)++] = (unsigned char)str_buffer[i] + 3;
            }
        }
        str_len = 0; // protect against a sequence of stray UTF8 continuation bytes
    }

    // merge the best consecutive pair each iteration, according the scores in vocab_scores
    while (1) {
        float best_score = -1e10;
        int best_id = -1;
        int best_idx = -1;

        for (int i=0; i < (*n_tokens-1); i++) {
            // check if we can merge the pair (tokens[i], tokens[i+1])
            sprintf(str_buffer, "%s%s", t->vocab[tokens[i]], t->vocab[tokens[i+1]]);
            int id = str_lookup(str_buffer, t->sorted_vocab, t->vocab_size);
            if (id != -1 && t->vocab_scores[id] > best_score) {
                // this merge pair exists in vocab! record its score and position
                best_score = t->vocab_scores[id];
                best_id = id;
                best_idx = i;
            }
        }

        if (best_idx == -1) {
            break; // we couldn't find any more pairs to merge, so we're done
        }

        // merge the consecutive pair (best_idx, best_idx+1) into new token best_id
        tokens[best_idx] = best_id;
        // delete token at position best_idx+1, shift the entire sequence back 1
        for (int i = best_idx+1; i < (*n_tokens-1); i++) {
            tokens[i] = tokens[i+1];
        }
        (*n_tokens)--; // token length decreased
    }

    // add optional EOS (=2) token, if desired
    if (eos) tokens[(*n_tokens)++] = 2;

    free(str_buffer);
}

// ----------------------------------------------------------------------------
// The Sampler, which takes logits and returns a sampled token
// sampling can be done in a few ways: greedy argmax, sampling, top-p sampling

typedef struct {
    float prob;
    int index;
} ProbIndex; // struct used when sorting probabilities during top-p sampling

typedef struct {
    int vocab_size;
    ProbIndex* probindex; // buffer used in top-p sampling
    float temperature;
    float topp;
    unsigned long long rng_state;
} Sampler;

int sample_argmax(float* probabilities, int n) {
    // return the index that has the highest probability
    int max_i = 0;
    float max_p = probabilities[0];
    for (int i = 1; i < n; i++) {
        if (probabilities[i] > max_p) {
            max_i = i;
            max_p = probabilities[i];
        }
    }
    return max_i;
}

int sample_mult(float* probabilities, int n, float coin) {
    // sample index from probabilities (they must sum to 1!)
    // coin is a random number in [0, 1), usually from random_f32()
    float cdf = 0.0f;
    for (int i = 0; i < n; i++) {
        cdf += probabilities[i];
        if (coin < cdf) {
            return i;
        }
    }
    return n - 1; // in case of rounding errors
}

int compare(const void* a, const void* b) {
    ProbIndex* a_ = (ProbIndex*) a;
    ProbIndex* b_ = (ProbIndex*) b;
    if (a_->prob > b_->prob) return -1;
    if (a_->prob < b_->prob) return 1;
    return 0;
}

int sample_topp(float* probabilities, int n, float topp, ProbIndex* probindex, float coin) {
    // top-p sampling (or "nucleus sampling") samples from the smallest set of
    // tokens that exceed probability topp. This way we never sample tokens that
    // have very low probabilities and are less likely to go "off the rails".
    // coin is a random number in [0, 1), usually from random_f32()

    int n0 = 0;
    // quicksort indices in descending order of probabilities
    // values smaller than (1 - topp) / (n - 1) cannot be part of the result
    // so for efficiency we crop these out as candidates before sorting
    const float cutoff = (1.0f - topp) / (n - 1);
    for (int i = 0; i < n; i++) {
        if (probabilities[i] >= cutoff) {
            probindex[n0].index = i;
            probindex[n0].prob = probabilities[i];
            n0++;
        }
    }
    qsort(probindex, n0, sizeof(ProbIndex), compare);

    // truncate the list where cumulative probability exceeds topp
    float cumulative_prob = 0.0f;
    int last_idx = n0 - 1; // in case of rounding errors consider all elements
    for (int i = 0; i < n0; i++) {
        cumulative_prob += probindex[i].prob;
        if (cumulative_prob > topp) {
            last_idx = i;
            break; // we've exceeded topp by including last_idx
        }
    }

    // sample from the truncated list
    float r = coin * cumulative_prob;
    float cdf = 0.0f;
    for (int i = 0; i <= last_idx; i++) {
        cdf += probindex[i].prob;
        if (r < cdf) {
            return probindex[i].index;
        }
    }
    return probindex[last_idx].index; // in case of rounding errors
}

void build_sampler(Sampler* sampler, int vocab_size, float temperature, float topp, unsigned long long rng_seed) {
    sampler->vocab_size = vocab_size;
    sampler->temperature = temperature;
    sampler->topp = topp;
    sampler->rng_state = rng_seed;
    // buffer only used with nucleus sampling; may not need but it's ~small
    sampler->probindex = malloc(sampler->vocab_size * sizeof(ProbIndex));
}

void free_sampler(Sampler* sampler) {
    free(sampler->probindex);
}

unsigned int random_u32(unsigned long long *state) {
    // xorshift rng: https://en.wikipedia.org/wiki/Xorshift#xorshift.2A
    *state ^= *state >> 12;
    *state ^= *state << 25;
    *state ^= *state >> 27;
    return (*state * 0x2545F4914F6CDD1Dull) >> 32;
}
float random_f32(unsigned long long *state) { // random float32 in [0,1)
    return (random_u32(state) >> 8) / 16777216.0f;
}

int sample(Sampler* sampler, float* logits) {
    // sample the token given the logits and some hyperparameters
    int next;
    if (sampler->temperature == 0.0f) {
        // greedy argmax sampling: take the token with the highest probability
        next = sample_argmax(logits, sampler->vocab_size);
    } else {
        // apply the temperature to the logits
        for (int q=0; q<sampler->vocab_size; q++) { logits[q] /= sampler->temperature; }
        // apply softmax to the logits to get the probabilities for next token
        softmax(logits, sampler->vocab_size);
        // flip a (float) coin (this is our source of entropy for sampling)
        float coin = random_f32(&sampler->rng_state);
        // we sample from this distribution to get the next token
        if (sampler->topp <= 0 || sampler->topp >= 1) {
            // simply sample from the predicted probability distribution
            next = sample_mult(logits, sampler->vocab_size, coin);
        } else {
            // top-p (nucleus) sampling, clamping the least likely tokens to zero
            next = sample_topp(logits, sampler->vocab_size, sampler->topp, sampler->probindex, coin);
        }
    }
    return next;
}

// ----------------------------------------------------------------------------
// generation loop

void generate(Transformer *transformer, Tokenizer *tokenizer, Sampler *sampler, char *prompt, int steps) {
    char *empty_prompt = "";
    if (prompt == NULL) { prompt = empty_prompt; }

    // encode the (string) prompt into tokens sequence
    int num_prompt_tokens = 0;
    int* prompt_tokens = (int*)malloc((strlen(prompt)+3) * sizeof(int)); // +3 for '\0', ?BOS, ?EOS
    encode(tokenizer, prompt, 1, 0, prompt_tokens, &num_prompt_tokens);
    if (num_prompt_tokens < 1) {
#ifdef C_TEST
        fprintf(stderr, "something is wrong, expected at least 1 prompt token\n");
        exit(EXIT_FAILURE);
#else
        printf("something is wrong, expected at least 1 prompt token\n");
#endif
    }

    // start the main loop
#ifndef C_TEST
    time_l start = 0;  // used to time our code, only initialized after first iteration
#endif
    int next;        // will store the next token in the sequence
    int token = prompt_tokens[0]; // kick off with the first token in the prompt
    int pos = 0;     // position in the sequence
    while (pos < steps) {

        // forward the transformer to get logits for the next token
        float* logits = forward(transformer, token, pos);

        // advance the state machine
        if (pos < num_prompt_tokens - 1) {
            // if we are still processing the input prompt, force the next prompt token
            next = prompt_tokens[pos + 1];
        } else {
            // otherwise sample the next token from the logits
            next = sample(sampler, logits);
        }
        pos++;

        // data-dependent terminating condition: the BOS (=1) token delimits sequences
        if (next == 1) { break; }

        // print the token as string, decode it with the Tokenizer object
        char* piece = decode(tokenizer, token, next);
        safe_printf(piece); // same as printf("%s", piece), but skips "unsafe" bytes
        fflush(stdout);
        token = next;

        // init the timer here because the first iteration can be slower
#ifndef C_TEST
        if (start == 0) { start = get_time(); }
#endif
    }
    printf("\n");

#ifndef C_TEST
    // report achieved tok/s (pos-1 because the timer starts after first iteration)
    if (pos > 1) {
        // long end = time_in_ms();
        // fprintf(stderr, "achieved tok/s: %f\n", (pos-1) / (double)(end-start)*1000);
        time_l end = get_time();
        float time_in_sec = (float)(end - start) / CLKS_PER_SEC;
        printf("achieved tok/s: %f\n", (pos-1) / time_in_sec);
    }
#endif

    free(prompt_tokens);
}



int main(int argc, char *argv[]) {

#ifndef C_TEST
    uart_init(115200);
#endif

    while (1)
    {
        // default parameters
        float temperature = 1.0f;   // 0.0 = greedy deterministic. 1.0 = original. don't set higher
        float topp = 0.9f;          // top-p in nucleus sampling. 1.0 = off. 0.9 works well, but slower
        int steps = 64;              // number of steps to run for
        char prompt[64];            // prompt string
#ifdef C_TEST
        unsigned long long rng_seed = (unsigned int)time(NULL); // seed rng with time by default
#else
        unsigned long long rng_seed = get_time(); // seed rng with time by default
#endif
        char *mode = "generate";    // generate|chat

        printf("20XXXXXXXX\n");     // TODO: 把 “20XXXXXXXX” 改成你的学号
        printf("Input prompt: ");
        scanf("%s", prompt);

        // build the Transformer via the model .bin file
        Transformer transformer;
        build_transformer(&transformer/*, checkpoint_path*/);
        if (steps == 0 || steps > transformer.config.seq_len) steps = transformer.config.seq_len; // override to ~max length

        // build the Tokenizer via the tokenizer .bin file
        Tokenizer tokenizer;
        build_tokenizer(&tokenizer, /*tokenizer_path,*/ transformer.config.vocab_size);

        // build the Sampler
        Sampler sampler;
        build_sampler(&sampler, transformer.config.vocab_size, temperature, topp, rng_seed);

        // run!
        generate(&transformer, &tokenizer, &sampler, prompt, steps);

        // memory and file handles cleanup
        free_sampler(&sampler);
        free_tokenizer(&tokenizer);
        free_transformer(&transformer);
    }

    return 0;
}
