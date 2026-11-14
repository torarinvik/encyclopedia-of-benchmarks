module backward_oracle_match;

fn long backward_oracle_match(long* values, usz length) @export("backward_oracle_match") {
    if (values == null || length < 2 || values[0] < 0 || values[0] > 4096 || values[1] < 0 || values[1] > 63) return -2;
    usz n = (usz)values[0];
    usz m = (usz)values[1];
    if (length != 2 + n + m) return -2;
    for (usz i = 2; i < length; i++) if (values[i] < 97 || values[i] > 122) return -2;
    if (m == 0) return 0;
    if (m > n) return -1;
    int[1664] next;
    int[64] suffix;
    for (usz i = 0; i < 1664; i++) next[i] = -1;
    for (usz i = 0; i < 64; i++) suffix[i] = -1;
    for (usz i = 0; i < m; i++) {
        usz letter = (usz)(values[2 + n + m - 1 - i] - 97);
        next[i * 26 + letter] = (int)(i + 1);
        int k = suffix[i];
        while (k >= 0 && next[(usz)k * 26 + letter] < 0) {
            next[(usz)k * 26 + letter] = (int)(i + 1);
            k = suffix[(usz)k];
        }
        suffix[i + 1] = k < 0 ? 0 : next[(usz)k * 26 + letter];
    }
    usz start = 0;
    while (start <= n - m) {
        usz state = 0, remaining = m, shift = m;
        while (remaining > 0) {
            remaining--;
            int dest = next[state * 26 + (usz)(values[2 + start + remaining] - 97)];
            if (dest < 0) { shift = remaining + 1; break; }
            state = (usz)dest;
            if (remaining == 0) return (long)start;
        }
        start += shift;
    }
    return -1;
}
