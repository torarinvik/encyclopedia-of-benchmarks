#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 10000000, PRIME_LIMIT = 3162, PRIME_CAPACITY = 500, SEGMENT_SIZE = 32768 };

static int same_digits(uint32_t left, uint32_t right)
{
    int counts[10] = {0};
    while (left != 0) { ++counts[left % 10]; left /= 10; }
    while (right != 0) { --counts[right % 10]; right /= 10; }
    for (int digit = 0; digit < 10; ++digit) if (counts[digit] != 0) return 0;
    return 1;
}

int64_t problem70(int64_t max_n)
{
    if (max_n < 0 || max_n > MAX_N) return -1;
    const uint32_t limit = (uint32_t)max_n;
    uint8_t is_prime[PRIME_LIMIT + 1] = {0};
    uint32_t primes[PRIME_CAPACITY];
    size_t prime_count = 0;
    for (uint32_t value = 2; value <= PRIME_LIMIT && value <= limit / value; ++value) is_prime[value] = 1;
    for (uint32_t prime = 2; prime <= PRIME_LIMIT && prime <= limit / prime; ++prime) {
        if (!is_prime[prime]) continue;
        for (uint32_t multiple = prime * prime; multiple <= PRIME_LIMIT && multiple <= limit / multiple; multiple += prime)
            is_prime[multiple] = 0;
    }
    for (uint32_t value = 2; value <= PRIME_LIMIT && value <= limit / value; ++value)
        if (is_prime[value]) primes[prime_count++] = value;

    uint32_t phi[SEGMENT_SIZE], remainder[SEGMENT_SIZE];
    uint32_t best_n = 1, best_phi = 0;
    for (uint32_t low = 0; low <= limit;) {
        uint32_t high = low + SEGMENT_SIZE - 1;
        if (high < low || high > limit) high = limit;
        const uint32_t length = high - low + 1;
        for (uint32_t offset = 0; offset < length; ++offset) {
            phi[offset] = low + offset;
            remainder[offset] = low + offset;
        }
        for (size_t index = 0; index < prime_count; ++index) {
            const uint32_t prime = primes[index];
            uint32_t first = low + (prime - low % prime) % prime;
            if (first < prime) first = prime;
            for (uint32_t multiple = first; multiple <= high;) {
                const uint32_t offset = multiple - low;
                phi[offset] -= phi[offset] / prime;
                while (remainder[offset] % prime == 0) remainder[offset] /= prime;
                if (high - multiple < prime) break;
                multiple += prime;
            }
        }
        for (uint32_t offset = 0; offset < length; ++offset) {
            if (remainder[offset] > 1) phi[offset] -= phi[offset] / remainder[offset];
            const uint32_t number = low + offset;
            if (number < 2) continue;
            if ((uint64_t)number * best_phi < (uint64_t)best_n * phi[offset]
                    && same_digits(number, phi[offset])) {
                best_n = number;
                best_phi = phi[offset];
            }
        }
        if (high == limit) break;
        low = high + 1;
    }
    return (int64_t)best_n;
}
