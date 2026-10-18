#include <stddef.h>
#include <stdint.h>

#define MAX_N INT64_C(1000005)

int64_t smallest_prime_factor(const int64_t *input, size_t length) {
    if (input == NULL || length != 1u) return -1;
    const int64_t n = input[0];
    if (n < 2 || n > MAX_N) return -1;
    int64_t factor = 2;
    while (factor <= n / factor) {
        if (n % factor == 0) return factor;
        ++factor;
    }
    return n;
}
