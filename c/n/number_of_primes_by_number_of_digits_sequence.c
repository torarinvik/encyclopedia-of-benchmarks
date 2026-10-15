#include <stdint.h>

static int is_prime(int64_t value) {
    if (value < 2) return 0;
    for (int64_t factor = 2; factor <= value / factor; ++factor) {
        if (value % factor == 0) return 0;
    }
    return 1;
}

int64_t number_of_primes_by_number_of_digits_sequence(int64_t index) {
    if (index < 0 || index > 3) return -1;
    if (index == 0) return 0;
    int64_t lower = 1;
    for (int64_t i = 1; i < index; ++i) lower *= 10;
    int64_t upper = lower * 10;
    int64_t count = 0;
    for (int64_t value = lower + 1; value <= upper; ++value) {
        count += is_prime(value);
    }
    return count;
}
