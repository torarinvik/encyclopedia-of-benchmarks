module recamans_sequence;

fn long recamans_sequence(long index) @export("recamans_sequence") {
    if (index < 0 || index > 32) return -1;
    bool[529] seen;
    for (usz i = 0; i < 529; i++) seen[i] = false;
    seen[0] = true;
    long previous = 0;
    for (long step = 1; step <= index; step += 1) {
        long candidate = previous - step;
        if (candidate < 0 || seen[(usz)candidate]) candidate = previous + step;
        seen[(usz)candidate] = true;
        previous = candidate;
    }
    return previous;
}
