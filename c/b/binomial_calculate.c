#include <stddef.h>
#include <stdint.h>

int64_t binomial_calculate(const int64_t *input, size_t length)
{
    if (input == NULL || length != 2) return -1;
    int64_t n = input[0], k = input[1];
    if (n < 0 || n > 62 || k < 0 || k > n) return -1;
    if (k > n / 2) k = n - k;
    uint64_t result = 1;
    for (int64_t i = 1; i <= k; ++i) {
        result *= (uint64_t)(n - k + i);
        result /= (uint64_t)i;
    }
    return (int64_t)result;
}
