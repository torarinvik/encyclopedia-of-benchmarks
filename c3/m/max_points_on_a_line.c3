module max_points_on_a_line;

const usz MAX_N = 16, MAX_INPUT = 34, TABLE_SIZE = 32;

fn long gcd_positive(long a, long b) {
    while (b != 0) { long remainder = a % b; a = b; b = remainder; }
    return a;
}

fn long max_points_on_a_line(long* input, usz length) @export("max_points_on_a_line") {
    if (input == null || length < 3 || length > MAX_INPUT) return -1;
    long n_value = input[0];
    if (n_value < 1 || n_value > (long)MAX_N || length != (usz)(1 + 2 * n_value)) return -1;
    usz n = (usz)n_value;
    long[MAX_N] x = {}, y = {};
    for (usz i = 0; i < n; ++i) {
        long xv = input[1 + 2 * i], yv = input[2 + 2 * i];
        if (xv < -100 || xv > 100 || yv < -100 || yv > 100) return -1;
        x[i] = xv; y[i] = yv;
        for (usz j = 0; j < i; ++j) if (x[i] == x[j] && y[i] == y[j]) return -1;
    }
    if (n == 1) return 1;
    long answer = 2;
    for (usz anchor = 0; anchor < n; ++anchor) {
        long[TABLE_SIZE] keys;
        usz[TABLE_SIZE] counts = {};
        for (usz slot = 0; slot < TABLE_SIZE; ++slot) keys[slot] = -1;
        usz best = 0;
        for (usz other = 0; other < n; ++other) {
            if (other == anchor) continue;
            long dx = x[other] - x[anchor], dy = y[other] - y[anchor];
            long divisor = gcd_positive(dx < 0 ? -dx : dx, dy < 0 ? -dy : dy);
            dx /= divisor; dy /= divisor;
            if (dx < 0 || (dx == 0 && dy < 0)) { dx = -dx; dy = -dy; }
            long direction_key = dx * 401 + dy + 200;
            usz slot = (usz)(direction_key % (long)TABLE_SIZE);
            while (keys[slot] != -1 && keys[slot] != direction_key) slot = (slot + 1) % TABLE_SIZE;
            if (keys[slot] == -1) keys[slot] = direction_key;
            counts[slot]++;
            if (counts[slot] > best) best = counts[slot];
        }
        if ((long)(best + 1) > answer) answer = (long)(best + 1);
    }
    return answer;
}
