package edu.hitsz.observer;

/**
 * Observer for prop effects.
 */
public interface PropObserver {
    /**
     * Handle bomb effect.
     *
     * @return score gained by this observer
     */
    int onBombEffect();

    /**
     * Handle freeze effect.
     */
    void onFreezeEffect();
}
