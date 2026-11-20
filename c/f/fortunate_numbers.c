#include <stddef.h>
#include <stdint.h>

#define MAX_PARSEABLE_LENGTH 2
#define MAX_N 10
#define SEARCH_MAX 64

static int is_prime_trial(int64_t value) {
    if (value < 2) return 0;
    for (int64_t divisor = 2; divisor <= value / divisor; ++divisor) {
        if (value % divisor == 0) return 0;
    }
    return 1;
}

int64_t fortunate_numbers(const int64_t *input, size_t length) {
    if (input == NULL || length < 1 || length > MAX_PARSEABLE_LENGTH) return -1;
    if (length != 1 || input[0] < 1 || input[0] > MAX_N) return -1;

    const int64_t n = input[0];
    int64_t primorial = 1;
    int64_t primes_found = 0;
    for (int64_t candidate = 2; primes_found < n; ++candidate) {
        if (is_prime_trial(candidate)) {
            primorial *= candidate;
            ++primes_found;
        }
    }
    for (int64_t offset = 2; offset <= SEARCH_MAX; ++offset) {
        if (is_prime_trial(primorial + offset)) return offset;
    }
    return -2;
}
