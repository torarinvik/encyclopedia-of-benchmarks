/* Clean-room row recurrence for the Entringer triangle. */
#include <stddef.h>
#include <stdint.h>

int64_t entringer_number(const int64_t *values, size_t length) {
    if (values == NULL || length != 2) return -1;
    const int64_t n = values[0], target = values[1];
    if (n < 0 || n > 12 || target < 0 || target > n) return -1;
    int64_t previous[13] = {1};
    int64_t current[13] = {0};
    for (int64_t row = 1; row <= n; ++row) {
        current[0] = 0;
        for (int64_t col = 1; col <= row; ++col)
            current[col] = current[col - 1] + previous[row - col];
        for (size_t i = 0; i < 13; ++i) {
            previous[i] = current[i];
            current[i] = 0;
        }
    }
    return previous[target];
}
