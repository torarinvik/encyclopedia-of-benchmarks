#include <stddef.h>
#include <stdint.h>

int64_t backward_nondeterministic_dawg_match(const int64_t *values, size_t length) {
    if (values == NULL || length < 2 || values[0] < 0 || values[0] > 4096 ||
        values[1] < 0 || values[1] > 63) return -2;
    size_t n = (size_t)values[0], m = (size_t)values[1];
    if (length != 2 + n + m) return -2;
    for (size_t i = 2; i < length; ++i)
        if (values[i] < 97 || values[i] > 122) return -2;
    if (m == 0) return 0;
    if (m > n) return -1;

    uint64_t masks[26] = {0};
    for (size_t i = 0; i < m; ++i)
        masks[(size_t)(values[2 + n + i] - 97)] |= UINT64_C(1) << (m - 1 - i);
    size_t start = 0;
    while (start <= n - m) {
        size_t remaining = m, shift = m;
        uint64_t states = UINT64_MAX;
        while (remaining > 0 && states != 0) {
            --remaining;
            states &= masks[(size_t)(values[2 + start + remaining] - 97)];
            if (states != 0) {
                if (remaining == 0) return (int64_t)start;
                shift = remaining;
            }
            states <<= 1;
        }
        start += shift;
    }
    return -1;
}
