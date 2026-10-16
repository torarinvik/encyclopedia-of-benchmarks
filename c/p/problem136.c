#include <stdint.h>

int64_t problem136(int64_t n_limit)
{
    if (n_limit > 100000) return -1;
    if (n_limit <= 0) return 0;
    uint8_t solutions[100000] = {0};
    const int64_t max_delta = (n_limit + 1) / 4;
    for (int64_t delta = 1; delta <= max_delta; ++delta) {
        for (int64_t y = 4 * delta - 1; y > delta; --y) {
            const int64_t n = y * (4 * delta - y);
            if (n >= n_limit) break;
            if (solutions[n] < 2) ++solutions[n];
        }
    }
    int64_t answer = 0;
    for (int64_t n = 0; n < n_limit; ++n) if (solutions[n] == 1) ++answer;
    return answer;
}
