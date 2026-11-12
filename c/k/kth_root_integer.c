#include <stddef.h>
#include <stdint.h>

static int power_at_most(int64_t base, int64_t exponent, int64_t limit) {
    if (base == 0) return 1;
    int64_t product = 1;
    while (exponent > 0) {
        if (product > limit / base) return 0;
        product *= base;
        --exponent;
    }
    return 1;
}

int64_t kth_root_integer(const int64_t *input, size_t length) {
    if (input == NULL || length != 2) return -1;
    const int64_t number = input[0];
    const int64_t degree = input[1];
    if (number < 0 || degree < 1 || degree > 64) return -1;

    int64_t low = 0;
    int64_t high = number;
    while (low < high) {
        const int64_t difference = high - low;
        const int64_t candidate = low + difference / 2 + difference % 2;
        if (power_at_most(candidate, degree, number)) low = candidate;
        else high = candidate - 1;
    }
    return low;
}
