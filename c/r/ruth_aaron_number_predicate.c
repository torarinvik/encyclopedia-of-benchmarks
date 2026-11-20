#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 100000, MAX_PARSEABLE_LENGTH = 2 };

static int64_t prime_factor_sum_counted(int64_t value) {
    int64_t total = 0;
    for (int64_t divisor = 2; divisor <= value / divisor; ++divisor) {
        while (value % divisor == 0) {
            total += divisor;
            value /= divisor;
        }
    }
    if (value > 1) total += value;
    return total;
}

int64_t ruth_aaron_number_predicate(const int64_t *input, size_t length) {
    if (input == NULL || length < 1U || length > MAX_PARSEABLE_LENGTH) return -1;
    if (length != 1U || input[0] < 1 || input[0] > MAX_N) return -1;
    const int64_t n = input[0];
    return prime_factor_sum_counted(n) == prime_factor_sum_counted(n + 1) ? 1 : 0;
}
