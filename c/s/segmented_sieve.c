#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_N 10000
#define MAX_BASE_PRIMES 25
#define MAX_PRIMES 1229

static void put_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t segmented_sieve(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length != 1 || input[0] < 2 || input[0] > MAX_N) return -1;
    const size_t n = (size_t)input[0];
    size_t end = 0;
    while ((end + 1) * (end + 1) <= n) ++end;
    bool base_marks[101] = {false};
    int64_t base[MAX_BASE_PRIMES];
    size_t base_count = 0;
    for (size_t i = 2; i <= end; ++i) base_marks[i] = true;
    for (size_t p = 2; p <= end; ++p) {
        if (!base_marks[p]) continue;
        base[base_count++] = (int64_t)p;
        for (size_t multiple = p * p; multiple <= end; multiple += p) base_marks[multiple] = false;
    }
    int64_t primes[MAX_PRIMES];
    size_t prime_count = 0;
    for (size_t i = 0; i < base_count; ++i) primes[prime_count++] = base[i];
    size_t low = end + 1;
    size_t high = 2 * end < n ? 2 * end : n;
    while (low <= n) {
        bool segment[201] = {false};
        size_t segment_length = high - low + 1;
        for (size_t i = 0; i < segment_length; ++i) segment[i] = true;
        for (size_t i = 0; i < base_count; ++i) {
            size_t p = (size_t)base[i];
            size_t first = (low / p) * p;
            if (first < low) first += p;
            for (size_t multiple = first; multiple <= high; multiple += p) segment[multiple - low] = false;
        }
        for (size_t i = 0; i < segment_length; ++i) if (segment[i]) primes[prime_count++] = (int64_t)(low + i);
        low = high + 1;
        high = high + end < n ? high + end : n;
    }
    const size_t output_length = prime_count * 8;
    if (capacity < output_length || (output_length > 0 && output == NULL)) return -2;
    for (size_t i = 0; i < prime_count; ++i) put_i64_le(output, i * 8, primes[i]);
    return (int64_t)output_length;
}
