#include <stdint.h>

int64_t problem124(int64_t n_max, int64_t k)
{
    if (n_max < 1 || n_max > 100000 || k < 1 || k > n_max) return -1;
    const int n = (int)n_max;
    uint32_t radicals[100001];
    uint32_t counts[100001] = {0};
    for (int i = 1; i <= n; ++i) radicals[i] = 1;
    for (int p = 2; p <= n; ++p) {
        if (radicals[p] == 1) {
            for (int multiple = p; multiple <= n; multiple += p) radicals[multiple] *= (uint32_t)p;
        }
    }
    for (int i = 1; i <= n; ++i) ++counts[radicals[i]];
    uint32_t remaining = (uint32_t)k;
    for (int rad = 1; rad <= n; ++rad) {
        if (remaining > counts[rad]) { remaining -= counts[rad]; continue; }
        for (int value = 1; value <= n; ++value) {
            if (radicals[value] == (uint32_t)rad && --remaining == 0) return value;
        }
    }
    return -1;
}
