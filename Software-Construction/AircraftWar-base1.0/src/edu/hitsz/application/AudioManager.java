package edu.hitsz.application;

import javax.sound.sampled.AudioInputStream;
import javax.sound.sampled.AudioSystem;
import javax.sound.sampled.Clip;
import javax.sound.sampled.LineUnavailableException;
import javax.sound.sampled.UnsupportedAudioFileException;
import java.io.BufferedInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

/**
 * 统一管理背景音乐与音效播放。
 */
public class AudioManager {

    private static final String BGM_FILE = "bgm.wav";
    private static final String BOSS_BGM_FILE = "bgm_boss.wav";
    private static final String BULLET_HIT_FILE = "bullet_hit.wav";
    private static final String BOMB_EXPLOSION_FILE = "bomb_explosion.wav";
    private static final String SUPPLY_FILE = "get_supply.wav";
    private static final String GAME_OVER_FILE = "game_over.wav";

    private static final AudioManager INSTANCE = new AudioManager();

    private final ExecutorService effectExecutor;

    private Clip bgmClip;
    private Clip bossBgmClip;

    private Path audioBaseDir;
    private boolean audioEnabled = true;
    private boolean audioErrorLogged = false;

    private AudioManager() {
        this.effectExecutor = Executors.newSingleThreadExecutor(r -> {
            Thread thread = new Thread(r, "audio-effect-thread");
            thread.setDaemon(true);
            return thread;
        });
    }

    public static AudioManager getInstance() {
        return INSTANCE;
    }

    public synchronized void playBackgroundLoop() {
        if (!audioEnabled) {
            return;
        }
        bgmClip = startLoopClip(bgmClip, BGM_FILE);
    }

    public synchronized void stopBackgroundLoop() {
        bgmClip = stopAndClose(bgmClip);
    }

    public synchronized void playBossBackgroundLoop() {
        if (!audioEnabled) {
            return;
        }
        stopBackgroundLoop();
        bossBgmClip = startLoopClip(bossBgmClip, BOSS_BGM_FILE);
    }

    public synchronized void stopBossBackgroundLoop() {
        bossBgmClip = stopAndClose(bossBgmClip);
    }

    public synchronized void stopAllLoopMusic() {
        stopBackgroundLoop();
        stopBossBackgroundLoop();
    }

    public void playBulletHitEffect() {
        playOneShot(BULLET_HIT_FILE);
    }

    public void playBombExplosionEffect() {
        playOneShot(BOMB_EXPLOSION_FILE);
    }

    public void playSupplyEffect() {
        playOneShot(SUPPLY_FILE);
    }

    public void playGameOverEffect() {
        playOneShot(GAME_OVER_FILE);
    }

    private synchronized Clip startLoopClip(Clip existingClip, String fileName) {
        if (existingClip != null) {
            if (existingClip.isRunning()) {
                return existingClip;
            }
            existingClip.setFramePosition(0);
            existingClip.loop(Clip.LOOP_CONTINUOUSLY);
            existingClip.start();
            return existingClip;
        }

        Clip clip = createClip(fileName);
        if (clip == null) {
            return null;
        }
        clip.loop(Clip.LOOP_CONTINUOUSLY);
        clip.start();
        return clip;
    }

    private Clip stopAndClose(Clip clip) {
        if (clip == null) {
            return null;
        }
        clip.stop();
        clip.flush();
        clip.close();
        return null;
    }

    private void playOneShot(String fileName) {
        if (!audioEnabled) {
            return;
        }
        effectExecutor.execute(() -> {
            Clip clip = createClip(fileName);
            if (clip == null) {
                return;
            }
            try {
                clip.start();
                while (clip.isRunning()) {
                    Thread.sleep(10L);
                }
            } catch (InterruptedException ex) {
                Thread.currentThread().interrupt();
            } finally {
                clip.close();
            }
        });
    }

    private Clip createClip(String fileName) {
        if (!audioEnabled) {
            return null;
        }

        try (AudioInputStream audioInputStream = openAudioInputStream(fileName)) {
            Clip clip = AudioSystem.getClip();
            clip.open(audioInputStream);
            return clip;
        } catch (UnsupportedAudioFileException | IOException | LineUnavailableException ex) {
            disableAudio("Audio playback disabled. Cannot load: " + fileName, ex);
            return null;
        }
    }

    private AudioInputStream openAudioInputStream(String fileName)
            throws UnsupportedAudioFileException, IOException {
        InputStream resourceStream = AudioManager.class.getResourceAsStream("/videos/" + fileName);
        if (resourceStream != null) {
            return AudioSystem.getAudioInputStream(new BufferedInputStream(resourceStream));
        }

        Path audioPath = resolveAudioBaseDir().resolve(fileName);
        return AudioSystem.getAudioInputStream(audioPath.toFile());
    }

    private Path resolveAudioBaseDir() throws IOException {
        if (audioBaseDir != null) {
            return audioBaseDir;
        }

        String customAudioDir = System.getProperty("aircraftwar.audioDir");
        if (customAudioDir != null) {
            Path customPath = Paths.get(customAudioDir).toAbsolutePath().normalize();
            if (Files.isDirectory(customPath) && hasCoreAudioFiles(customPath)) {
                audioBaseDir = customPath;
                return audioBaseDir;
            }
        }

        Path[] quickCandidates = {
                Paths.get("src", "videos"),
                Paths.get("Software-Construction", "AircraftWar-base1.0", "src", "videos")
        };
        for (Path candidate : quickCandidates) {
            Path absoluteCandidate = candidate.toAbsolutePath().normalize();
            if (Files.isDirectory(absoluteCandidate) && hasCoreAudioFiles(absoluteCandidate)) {
                audioBaseDir = absoluteCandidate;
                return audioBaseDir;
            }
        }

        Path cwd = Paths.get("").toAbsolutePath().normalize();
        try (java.util.stream.Stream<Path> stream = Files.walk(cwd, 6)) {
            Path matched = stream
                    .filter(Files::isDirectory)
                    .filter(path -> path.getFileName() != null && "videos".equals(path.getFileName().toString()))
                    .filter(path -> {
                        Path parent = path.getParent();
                        return parent != null
                                && parent.getFileName() != null
                                && "src".equals(parent.getFileName().toString());
                    })
                    .filter(this::hasCoreAudioFiles)
                    .findFirst()
                    .orElse(null);
            if (matched != null) {
                audioBaseDir = matched;
                return audioBaseDir;
            }
        }

        throw new IOException("Cannot locate audio assets directory. Expected folder: src/videos");
    }

    private boolean hasCoreAudioFiles(Path dir) {
        return Files.isRegularFile(dir.resolve(BGM_FILE))
                && Files.isRegularFile(dir.resolve(BOSS_BGM_FILE))
                && Files.isRegularFile(dir.resolve(GAME_OVER_FILE));
    }

    private synchronized void disableAudio(String message, Exception ex) {
        if (!audioEnabled) {
            return;
        }
        audioEnabled = false;
        stopAllLoopMusic();
        if (!audioErrorLogged) {
            audioErrorLogged = true;
            System.err.println(message);
            System.err.println(ex.getMessage());
        }
    }
}
