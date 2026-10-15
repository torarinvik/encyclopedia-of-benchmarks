#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT INT64_C(-1)
#define MAX_ROD_LENGTH 30
#define MAX_PRICE INT64_C(1000)

int64_t rod_cutting(const int64_t *values, size_t length)
{
    if (values == NULL || length < 2) return INVALID_RESULT;
    const int64_t n_value = values[0];
    if (n_value < 1 || n_value > MAX_ROD_LENGTH) return INVALID_RESULT;
    const size_t n = (size_t)n_value;
    if (length != n + 1) return INVALID_RESULT;
    for (size_t i = 0; i < n; ++i) {
        if (values[i + 1] < 1 || values[i + 1] > MAX_PRICE) return INVALID_RESULT;
    }
    int64_t profit[MAX_ROD_LENGTH + 1] = {0};
    for (size_t rod = 1; rod <= n; ++rod) {
        int64_t best = 0;
        for (size_t cut = 1; cut <= rod; ++cut) {
            const int64_t candidate = values[cut] + profit[rod - cut];
            if (candidate > best) best = candidate;
        }
        profit[rod] = best;
    }
    return profit[n];
}
