/* Primes strictly between bounded prime endpoints, encoded as ASCII. */
#include <stddef.h>
#include <stdint.h>

#define MIN_ENDPOINT 2
#define MAX_ENDPOINT 997
#define MAX_PRIME_COUNT 256

static int is_prime_candidate(int64_t value)
{
    if (value < 2) return 0;
    for (int64_t divisor = 2; divisor <= value / divisor; ++divisor) {
        if (value % divisor == 0) return 0;
    }
    return 1;
}

static size_t decimal_length(int64_t value)
{
    if (value >= 100) return 3;
    if (value >= 10) return 2;
    return 1;
}

static size_t write_decimal(uint8_t *output, size_t offset, int64_t value)
{
    if (value >= 100) {
        output[offset++] = (uint8_t)('0' + value / 100);
        value %= 100;
    }
    if (value >= 10) {
        output[offset++] = (uint8_t)('0' + value / 10);
        value %= 10;
    }
    output[offset++] = (uint8_t)('0' + value);
    return offset;
}

int64_t get_primes_between(const int64_t *values, size_t length,
                           uint8_t *output, size_t output_capacity)
{
    if (values == NULL || length != 2) return -1;
    const int64_t p1 = values[0];
    const int64_t p2 = values[1];
    if (p1 < MIN_ENDPOINT || p1 > MAX_ENDPOINT ||
        p2 < MIN_ENDPOINT || p2 > MAX_ENDPOINT || p1 >= p2 ||
        !is_prime_candidate(p1) || !is_prime_candidate(p2)) return -1;

    int64_t primes[MAX_PRIME_COUNT];
    size_t count = 0;
    for (int64_t candidate = p1 + 1; candidate < p2; ++candidate) {
        if (is_prime_candidate(candidate)) primes[count++] = candidate;
    }
    if (count == 0) return -1;

    size_t required = count - 1;
    for (size_t i = 0; i < count; ++i) required += decimal_length(primes[i]);
    if (output == NULL || output_capacity < required) return -2;

    size_t written = 0;
    for (size_t i = 0; i < count; ++i) {
        if (i != 0) output[written++] = ',';
        written = write_decimal(output, written, primes[i]);
    }
    return (int64_t)written;
}
