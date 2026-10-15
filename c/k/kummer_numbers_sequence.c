#include <stdint.h>

static int is_prime(int64_t value) {
    if (value < 2) return 0;
    for (int64_t factor = 2; factor <= value / factor; ++factor) {
        if (value % factor == 0) return 0;
    }
    return 1;
}

int64_t kummer_numbers_sequence(int64_t index) {
    if (index < 0 || index > 14) return -1;
    int64_t product = 1;
    int64_t prime_count = 0;
    for (int64_t candidate = 2; prime_count < index + 1; ++candidate) {
        if (is_prime(candidate)) {
            product *= candidate;
            ++prime_count;
        }
    }
    return product - 1;
}
