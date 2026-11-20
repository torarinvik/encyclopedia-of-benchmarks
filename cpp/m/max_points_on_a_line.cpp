#include <cstddef>
#include <cstdint>

namespace {
int gcd_positive(int a, int b) {
    while (b != 0) { const int remainder = a % b; a = b; b = remainder; }
    return a;
}
}

extern "C" std::int64_t max_points_on_a_line(const std::int64_t *input, std::size_t length) {
    constexpr int max_n = 16, table_size = 32;
    if (input == nullptr || length < 3 || length > 34) return -1;
    const std::int64_t n_value = input[0];
    if (n_value < 1 || n_value > max_n || length != static_cast<std::size_t>(1 + 2 * n_value)) return -1;
    const int n = static_cast<int>(n_value);
    int x[max_n], y[max_n];
    for (int i = 0; i < n; ++i) {
        const auto xv = input[1 + 2 * i], yv = input[2 + 2 * i];
        if (xv < -100 || xv > 100 || yv < -100 || yv > 100) return -1;
        x[i] = static_cast<int>(xv); y[i] = static_cast<int>(yv);
        for (int j = 0; j < i; ++j) if (x[i] == x[j] && y[i] == y[j]) return -1;
    }
    if (n == 1) return 1;
    std::int64_t answer = 2;
    for (int anchor = 0; anchor < n; ++anchor) {
        int keys[table_size], counts[table_size]{};
        for (int &key : keys) key = -1;
        int best = 0;
        for (int other = 0; other < n; ++other) {
            if (other == anchor) continue;
            int dx = x[other] - x[anchor], dy = y[other] - y[anchor];
            const int divisor = gcd_positive(dx < 0 ? -dx : dx, dy < 0 ? -dy : dy);
            dx /= divisor; dy /= divisor;
            if (dx < 0 || (dx == 0 && dy < 0)) { dx = -dx; dy = -dy; }
            const int direction_key = dx * 401 + dy + 200;
            int slot = direction_key % table_size;
            while (keys[slot] != -1 && keys[slot] != direction_key) slot = (slot + 1) % table_size;
            if (keys[slot] == -1) keys[slot] = direction_key;
            if (++counts[slot] > best) best = counts[slot];
        }
        if (best + 1 > answer) answer = best + 1;
    }
    return answer;
}
