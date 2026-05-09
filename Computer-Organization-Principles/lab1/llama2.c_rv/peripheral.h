#ifndef PERIPHERAL_H
#define PERIPHERAL_H

typedef unsigned long long time_l;

#define CLKS_PER_SEC 50000000

time_l get_time(void);

void uart_init(int baud_rate);

int printf(const char *format, ...);

#define SCAN_BUF_SIZE 128
int scanf(const char *format, ...);

#endif
