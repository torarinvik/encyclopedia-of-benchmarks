#include <stddef.h>
#include <stdint.h>

#define ES_MAX_PRIME INT64_C(100000)

static int es_is_prime(int64_t value) {
    if (value < 2) return 0;
    if (value % 2 == 0) return value == 2;
    for (int64_t divisor = 3; divisor <= value / divisor; divisor += 2) {
        if (value % divisor == 0) return 0;
    }
    return 1;
}

static int64_t es_class_for_prime(int64_t prime, int64_t direction) {
    int64_t remainder = prime + direction;
    int64_t result = 1;
    for (int64_t divisor = 2; divisor <= remainder / divisor; ++divisor) {
        if (remainder % divisor != 0) continue;
        if (divisor > 3) {
            const int64_t candidate = 1 + es_class_for_prime(divisor, direction);
            if (candidate > result) result = candidate;
        }
        do {
            remainder /= divisor;
        } while (remainder % divisor == 0);
    }
    if (remainder > 3) {
        const int64_t candidate = 1 + es_class_for_prime(remainder, direction);
        if (candidate > result) result = candidate;
    }
    return result;
}

int64_t erdos_selfridge_prime_class(const int64_t *input, size_t length) {
    if (input == NULL || length < 1U || length > 3U) return -1;
    if (length != 2U) return -1;
    const int64_t prime = input[0];
    const int64_t direction = input[1];
    if (prime < 2 || prime > ES_MAX_PRIME || (direction != -1 && direction != 1)) return -1;
    if (!es_is_prime(prime)) return -1;
    return es_class_for_prime(prime, direction);
}

