#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 16, MAX_PARSEABLE_LENGTH = 34, INVALID_RESULT = -1 };

int64_t minimum_area_rectangle_arbitrary_orientation(
    const int64_t *input, size_t length) {
    if (input == NULL || length < 1 || length > MAX_PARSEABLE_LENGTH)
        return INVALID_RESULT;
    const int64_t n_value = input[0];
    if (n_value < 4 || n_value > MAX_N) return INVALID_RESULT;
    const size_t n = (size_t)n_value;
    if (length != 1 + 2 * n) return INVALID_RESULT;

    int64_t x[MAX_N], y[MAX_N];
    for (size_t i = 0; i < n; ++i) {
        x[i] = input[1 + 2 * i];
        y[i] = input[2 + 2 * i];
        if (x[i] < -32 || x[i] > 32 || y[i] < -32 || y[i] > 32)
            return INVALID_RESULT;
        for (size_t j = 0; j < i; ++j)
            if (x[i] == x[j] && y[i] == y[j]) return INVALID_RESULT;
    }

    int64_t best = -1;
    for (size_t i = 0; i < n; ++i) {
        for (size_t j = i + 1; j < n; ++j) {
            const int64_t dx1 = x[i] - x[j], dy1 = y[i] - y[j];
            const int64_t midpoint_x = x[i] + x[j];
            const int64_t midpoint_y = y[i] + y[j];
            const int64_t length1 = dx1 * dx1 + dy1 * dy1;
            for (size_t k = 0; k < n; ++k) {
                for (size_t l = k + 1; l < n; ++l) {
                    if (k < i || (k == i && l <= j)) continue;
                    if (k == i || k == j || l == i || l == j) continue;
                    if (midpoint_x != x[k] + x[l]
                        || midpoint_y != y[k] + y[l]) continue;
                    const int64_t dx2 = x[k] - x[l], dy2 = y[k] - y[l];
                    if (length1 != dx2 * dx2 + dy2 * dy2) continue;
                    int64_t area2 = dx1 * dy2 - dy1 * dx2;
                    if (area2 < 0) area2 = -area2;
                    if (best < 0 || area2 < best) best = area2;
                }
            }
        }
    }
    return best < 0 ? 0 : best;
}
