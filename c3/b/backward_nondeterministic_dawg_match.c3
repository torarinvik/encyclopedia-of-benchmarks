module backward_nondeterministic_dawg_match;

fn long backward_nondeterministic_dawg_match(long* values, usz length) @export("backward_nondeterministic_dawg_match") {
    if (values == null || length < 2 || values[0] < 0 || values[0] > 4096 ||
        values[1] < 0 || values[1] > 63) return -2;
    usz n = (usz)values[0];
    usz m = (usz)values[1];
    if (length != 2 + n + m) return -2;
    for (usz i = 2; i < length; i++) {
        if (values[i] < 97 || values[i] > 122) return -2;
    }
    if (m == 0) return 0;
    if (m > n) return -1;

    ulong[26] masks = {};
    for (usz i = 0; i < m; i++) {
        usz letter = (usz)(values[2 + n + i] - 97);
        masks[letter] |= (ulong)1 << (m - 1 - i);
    }
    usz start = 0;
    while (start <= n - m) {
        usz remaining = m;
        usz shift = m;
        ulong states = ~(ulong)0;
        while (remaining > 0 && states != 0) {
            remaining--;
            states &= masks[(usz)(values[2 + start + remaining] - 97)];
            if (states != 0) {
                if (remaining == 0) return (long)start;
                shift = remaining;
            }
            states <<= 1;
        }
        start += shift;
    }
    return -1;
}
