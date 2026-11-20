#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 16, MAX_INPUT = 34, TABLE_SIZE = 32 };

static int gcd_positive(int a, int b) {
    while (b != 0) { const int remainder = a % b; a = b; b = remainder; }
    return a;
}

int64_t max_points_on_a_line(const int64_t *input, size_t length) {
    if (input == NULL || length < 3 || length > MAX_INPUT) return -1;
    const int64_t n_value = input[0];
    if (n_value < 1 || n_value > MAX_N || length != (size_t)(1 + 2 * n_value)) return -1;
    const size_t n = (size_t)n_value;
    int x[MAX_N], y[MAX_N];
    for (size_t i = 0; i < n; ++i) {
        const int64_t xv = input[1 + 2 * i], yv = input[2 + 2 * i];
        if (xv < -100 || xv > 100 || yv < -100 || yv > 100) return -1;
        x[i] = (int)xv; y[i] = (int)yv;
        for (size_t j = 0; j < i; ++j) if (x[i] == x[j] && y[i] == y[j]) return -1;
    }
    if (n == 1) return 1;
    int64_t answer = 2;
    for (size_t anchor = 0; anchor < n; ++anchor) {
        int key[TABLE_SIZE], count[TABLE_SIZE] = {0};
        for (size_t slot = 0; slot < TABLE_SIZE; ++slot) key[slot] = -1;
        int best = 0;
        for (size_t other = 0; other < n; ++other) {
            if (other == anchor) continue;
            int dx = x[other] - x[anchor], dy = y[other] - y[anchor];
            const int divisor = gcd_positive(dx < 0 ? -dx : dx, dy < 0 ? -dy : dy);
            dx /= divisor; dy /= divisor;
            if (dx < 0 || (dx == 0 && dy < 0)) { dx = -dx; dy = -dy; }
            const int direction_key = dx * 401 + dy + 200;
            int slot = direction_key % TABLE_SIZE;
            while (key[slot] != -1 && key[slot] != direction_key) slot = (slot + 1) % TABLE_SIZE;
            if (key[slot] == -1) key[slot] = direction_key;
            if (++count[slot] > best) best = count[slot];
        }
        if ((int64_t)(best + 1) > answer) answer = best + 1;
    }
    return answer;
}
