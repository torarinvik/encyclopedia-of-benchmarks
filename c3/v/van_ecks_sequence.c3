module van_ecks_sequence;

fn long van_ecks_sequence(long position) @export("van_ecks_sequence") {
    if (position < 1 || position > 16) return -1;
    long[17] last_seen;
    for (usz i = 0; i < 17; i++) last_seen[i] = 0;
    long previous = 0;
    for (long current = 2; current <= position; current += 1) {
        long next = 0;
        if (last_seen[(usz)previous] != 0) next = current - last_seen[(usz)previous];
        last_seen[(usz)previous] = current;
        previous = next;
    }
    return previous;
}
