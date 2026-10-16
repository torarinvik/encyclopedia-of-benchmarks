/* Search the source's positive-integer sequence using decimal digit counts. */
#include <stdint.h>

static void digit_counts(int64_t value, int counts[10]) {
    for (int i = 0; i < 10; ++i) counts[i] = 0;
    while (value > 0) { ++counts[value % 10]; value /= 10; }
}
static int same_digits(int64_t left, int64_t right) {
    int a[10], b[10]; digit_counts(left, a); digit_counts(right, b);
    for (int i = 0; i < 10; ++i) if (a[i] != b[i]) return 0;
    return 1;
}
int64_t problem52(int64_t unused) {
    if (unused != 0) return -1;
    for (int64_t value = 1;; ++value) {
        int matches = 1;
        for (int multiplier = 2; multiplier <= 6 && matches; ++multiplier)
            matches = same_digits(value, multiplier * value);
        if (matches) return value;
    }
}
