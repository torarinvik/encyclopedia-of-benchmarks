#include <stddef.h>
#include <stdint.h>

#define MAX_WORDS 2
#define MAX_COUNT 6
#define MAX_OUTPUT_VALUES 3

static int is_small_prime(uint64_t value) {
    if (value < 2) return 0;
    for (uint64_t divisor = 2; divisor <= value / divisor; ++divisor) {
        if (value % divisor == 0) return 0;
    }
    return 1;
}

static uint64_t multiply_mod(uint64_t left, uint64_t right, uint64_t modulus) {
    return (left * right) % modulus;
}

static uint64_t power_mod(uint64_t base, uint64_t exponent, uint64_t modulus) {
    uint64_t result = 1;
    base %= modulus;
    while (exponent != 0) {
        if ((exponent & 1) != 0) result = multiply_mod(result, base, modulus);
        exponent >>= 1;
        if (exponent != 0) base = multiply_mod(base, base, modulus);
    }
    return result;
}

static int is_prime_prefix(uint64_t value) {
    static const uint32_t small_primes[] = {2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37};
    static const uint32_t bases[] = {2, 7, 61};
    if (value < 2) return 0;
    for (size_t i = 0; i < sizeof(small_primes) / sizeof(small_primes[0]); ++i) {
        if (value == small_primes[i]) return 1;
        if (value % small_primes[i] == 0) return 0;
    }
    uint64_t odd_part = value - 1;
    unsigned twos = 0;
    while ((odd_part & 1) == 0) {
        odd_part >>= 1;
        ++twos;
    }
    for (size_t i = 0; i < sizeof(bases) / sizeof(bases[0]); ++i) {
        uint64_t witness = power_mod(bases[i], odd_part, value);
        if (witness == 1 || witness == value - 1) continue;
        unsigned round = 1;
        while (round < twos && witness != value - 1) {
            witness = multiply_mod(witness, witness, value);
            ++round;
        }
        if (witness != value - 1) return 0;
    }
    return 1;
}

int64_t smarandache_wellin_prime_prefix_scan(const int64_t *input, size_t length,
                                              uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || length > MAX_WORDS) return -1;
    if (input[0] < 0 || input[0] > MAX_COUNT || length != 1) return -1;

    uint64_t values[MAX_OUTPUT_VALUES] = {0};
    size_t result_count = 0;
    uint64_t prefix = 0;
    uint64_t candidate = 2;
    for (int64_t index = 0; index < input[0]; ++index) {
        while (!is_small_prime(candidate)) candidate += candidate == 2 ? 1 : 2;
        uint64_t scale = 10;
        while (scale <= candidate) scale *= 10;
        prefix = prefix * scale + candidate;
        if (is_prime_prefix(prefix)) values[result_count++] = prefix;
        candidate += candidate == 2 ? 1 : 2;
    }

    const size_t byte_count = result_count * 8;
    if (output == NULL || capacity < byte_count) return -2;
    uint8_t staged[MAX_OUTPUT_VALUES * 8] = {0};
    for (size_t item = 0; item < result_count; ++item) {
        for (size_t byte = 0; byte < 8; ++byte) {
            staged[item * 8 + byte] = (uint8_t)(values[item] >> (byte * 8));
        }
    }
    for (size_t byte = 0; byte < byte_count; ++byte) output[byte] = staged[byte];
    return (int64_t)byte_count;
}
