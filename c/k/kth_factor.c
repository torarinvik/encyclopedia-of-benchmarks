#include <stdint.h>

int64_t kth_factor(int64_t n_value, int64_t k_value)
{
    if (n_value < 1 || n_value > 10000 || k_value < 1 || k_value > n_value) return -1;
    const int32_t n = (int32_t)n_value;
    const int32_t k = (int32_t)k_value;
    int32_t factors_found = 0;
    for (int32_t i = 1; i <= n; ++i) {
        if (n % i == 0) {
            ++factors_found;
            if (factors_found == k) return i;
        }
    }
    return -1;
}
