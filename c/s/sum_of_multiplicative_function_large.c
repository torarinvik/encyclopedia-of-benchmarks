/* Min_25 sieve for f(p^e) = a*e + b*p modulo 469762049. */
#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>

#define MODULUS INT64_C(469762049)
#define MAX_N INT64_C(100000000)

static int64_t floor_sqrt(int64_t value)
{
    int64_t low = 1, high = 31623;
    while (low < high) {
        const int64_t middle = low + (high - low + 1) / 2;
        if (middle <= value / middle) low = middle;
        else high = middle - 1;
    }
    return low;
}

static int64_t triangular_mod(int64_t value)
{
    int64_t left = value, right = value + 1;
    if ((left & 1) == 0) left /= 2;
    else right /= 2;
    return ((left % MODULUS) * (right % MODULUS)) % MODULUS;
}

static size_t value_index(int64_t value, int64_t n, int64_t root, size_t size)
{
    return value <= root ? size - (size_t)value : (size_t)(n / value);
}

static int64_t normalize(int64_t value)
{
    value %= MODULUS;
    return value < 0 ? value + MODULUS : value;
}

int64_t sum_of_multiplicative_function_large(const int64_t *input, size_t length)
{
    if (input == NULL || length != 3) return -1;
    const int64_t n = input[0], a = input[1], b = input[2];
    if (n < 1 || n > MAX_N || a < 0 || a >= MODULUS || b < 0 || b >= MODULUS) return -1;

    const int64_t root = floor_sqrt(n);
    size_t high_count = (size_t)(n / root);
    while (high_count > 1 && n / (int64_t)(high_count - 1) == root) --high_count;
    const size_t size = high_count + (size_t)root;

    int64_t *quotients = calloc(size, sizeof(*quotients));
    int64_t *prime_count = calloc(size, sizeof(*prime_count));
    int64_t *prime_sum = calloc(size, sizeof(*prime_sum));
    uint8_t *composite = calloc((size_t)root + 1, sizeof(*composite));
    int64_t *primes = malloc(((size_t)root + 1) * sizeof(*primes));
    int64_t *values = calloc(size, sizeof(*values));
    int64_t *next_values = calloc(size, sizeof(*next_values));
    if (quotients == NULL || prime_count == NULL || prime_sum == NULL || composite == NULL ||
        primes == NULL || values == NULL || next_values == NULL) {
        free(quotients); free(prime_count); free(prime_sum); free(composite);
        free(primes); free(values); free(next_values);
        return -1;
    }

    for (size_t i = 1; i < high_count; ++i) quotients[i] = n / (int64_t)i;
    for (int64_t value = 1; value <= root; ++value) quotients[size - (size_t)value] = value;

    size_t prime_total = 0;
    for (int64_t value = 2; value <= root; ++value) {
        if (composite[value]) continue;
        primes[prime_total++] = value;
        if (value <= root / value) {
            for (int64_t multiple = value * value; multiple <= root; multiple += value) composite[multiple] = 1;
        }
    }

    for (size_t i = 1; i < size; ++i) {
        prime_count[i] = quotients[i] - 1;
        prime_sum[i] = normalize(triangular_mod(quotients[i]) - 1);
    }
    int64_t preceding_count = 0, preceding_sum = 0;
    for (size_t p_index = 0; p_index < prime_total; ++p_index) {
        const int64_t prime = primes[p_index];
        const int64_t square = prime * prime;
        for (size_t i = 1; i < size && quotients[i] >= square; ++i) {
            const size_t quotient_index = value_index(quotients[i] / prime, n, root, size);
            prime_count[i] -= prime_count[quotient_index] - preceding_count;
            const int64_t sum_delta = normalize(prime_sum[quotient_index] - preceding_sum);
            prime_sum[i] = normalize(prime_sum[i] - (prime % MODULUS) * sum_delta);
        }
        ++preceding_count;
        preceding_sum = normalize(preceding_sum + prime);
    }
    for (size_t i = 1; i < size; ++i) {
        prime_count[i] = ((a * (prime_count[i] % MODULUS)) + b * prime_sum[i]) % MODULUS;
        values[i] = prime_count[i];
        next_values[i] = prime_count[i];
    }

    for (size_t p_index = prime_total; p_index-- > 0;) {
        const int64_t prime = primes[p_index];
        int64_t power = prime;
        int64_t exponent = 1;
        const int64_t prime_prefix = values[value_index(prime, n, root, size)];
        while (n / prime >= power) {
            const int64_t local = (a * exponent + b * prime) % MODULUS;
            const int64_t next_local = (a * (exponent + 1) + b * prime) % MODULUS;
            const int64_t next_power = power * prime;
            for (size_t i = 1; i < size && next_power <= quotients[i]; ++i) {
                const size_t quotient_index = value_index(quotients[i] / power, n, root, size);
                const int64_t non_prime_sum = normalize(values[quotient_index] - prime_prefix);
                next_values[i] = normalize(next_values[i] + local * non_prime_sum + next_local);
            }
            power = next_power;
            ++exponent;
        }
        size_t copied = value_index(prime * prime, n, root, size) + 1;
        if (copied > size) copied = size;
        for (size_t i = 0; i < copied; ++i) values[i] = next_values[i];
    }

    const size_t answer_index = value_index(n, n, root, size);
    const int64_t answer = normalize(values[answer_index] + 1);
    free(quotients); free(prime_count); free(prime_sum); free(composite);
    free(primes); free(values); free(next_values);
    return answer;
}
