#include <stddef.h>
#include <stdint.h>

#define MAX_LIMIT INT64_C(1000000)
#define MAX_WORDS 15626

static int64_t count_primes(int64_t limit) {
    uint64_t bits[MAX_WORDS];
    for (size_t word = 0; word < MAX_WORDS; ++word) bits[word] = UINT64_MAX;
    int64_t count = 0;
    for (int64_t value = 2; value <= limit; ++value) {
        const size_t word = (size_t)((uint64_t)value >> 6);
        const uint64_t mask = UINT64_C(1) << ((uint64_t)value & 63U);
        if ((bits[word] & mask) != 0) {
            ++count;
            for (int64_t multiple = value + value; multiple <= limit; multiple += value) {
                const size_t multiple_word = (size_t)((uint64_t)multiple >> 6);
                const uint64_t multiple_mask = UINT64_C(1) << ((uint64_t)multiple & 63U);
                if ((bits[multiple_word] & multiple_mask) != 0) bits[multiple_word] ^= multiple_mask;
            }
        }
    }
    return count;
}

static void put_u64_le(uint8_t *output, size_t offset, uint64_t value) {
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(value >> (8 * byte));
}

int64_t benchmarkgame_nsieve_bits(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length != 1 || input[0] < 0 || input[0] > MAX_LIMIT) return -1;
    if (output == NULL || capacity < 24) return -2;
    for (size_t pass = 0; pass < 3; ++pass)
        put_u64_le(output, pass * 8, (uint64_t)count_primes(input[0] >> pass));
    return 24;
}
