#include <stddef.h>
#include <stdint.h>

#define MAX_T 16
#define MAX_N 16
#define MAX_MODULUS INT64_C(31)
#define MAX_PARSEABLE_INPUT_LENGTH 36

static int is_prime(int64_t value) {
    if (value < 2) return 0;
    for (int64_t divisor = 2; divisor <= value / divisor; ++divisor) {
        if (value % divisor == 0) return 0;
    }
    return 1;
}

static int64_t modular_power(int64_t base, size_t exponent, int64_t modulus) {
    int64_t result = 1;
    while (exponent > 0) {
        if ((exponent & 1U) != 0U) result = result * base % modulus;
        base = base * base % modulus;
        exponent >>= 1;
    }
    return result;
}

int64_t q_binomial_coefficient_prime_mod(
    const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 3 || length > MAX_PARSEABLE_INPUT_LENGTH) {
        return -1;
    }
    const int64_t count64 = input[0];
    const int64_t modulus = input[1];
    const int64_t q_value = input[2];
    if (count64 < 1 || count64 > MAX_T || modulus < 2
        || modulus > MAX_MODULUS || !is_prime(modulus)
        || q_value < 0 || q_value >= modulus) {
        return -1;
    }
    const size_t count = (size_t)count64;
    if (length != 3 + 2 * count) return -1;

    size_t max_n = 0;
    for (size_t query = 0; query < count; ++query) {
        const int64_t n64 = input[3 + 2 * query];
        const int64_t k64 = input[4 + 2 * query];
        if (n64 < 0 || n64 > MAX_N || k64 < 0 || k64 > MAX_N
            || n64 >= modulus || k64 >= modulus) {
            return -1;
        }
        if ((size_t)n64 > max_n) max_n = (size_t)n64;
    }
    if (output == NULL || capacity < count) return -2;

    int64_t table[MAX_N + 1][MAX_N + 1] = {{0}};
    table[0][0] = 1;
    for (size_t n = 1; n <= max_n; ++n) {
        table[n][0] = 1;
        for (size_t k = 1; k <= n; ++k) {
            const int64_t previous_same = k < n ? table[n - 1][k] : 0;
            const int64_t weight = modular_power(q_value, n - k, modulus);
            table[n][k] = (previous_same + weight * table[n - 1][k - 1])
                % modulus;
        }
    }

    for (size_t query = 0; query < count; ++query) {
        const size_t n = (size_t)input[3 + 2 * query];
        const size_t k = (size_t)input[4 + 2 * query];
        output[query] = (uint8_t)(k > n ? 0 : table[n][k]);
    }
    return (int64_t)count;
}
