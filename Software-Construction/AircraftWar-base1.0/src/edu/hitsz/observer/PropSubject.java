package edu.hitsz.observer;

/**
 * Subject for prop effects.
 */
public interface PropSubject {
    void addObserver(PropObserver observer);

    void removeObserver(PropObserver observer);

    void clearObservers();
}
