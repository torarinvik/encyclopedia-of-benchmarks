#include <stddef.h>
#include <stdint.h>

#define MAX_INPUT_LENGTH 2
#define MAX_LIMIT 1000

static int is_prime_count(uint16_t value) {
    if (value < 2) return 0;
    for (uint16_t divisor = 2; divisor <= value / divisor; ++divisor) {
        if (value % divisor == 0) return 0;
    }
    return 1;
}

static void store_i64(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & 255U);
        bits >>= 8;
    }
}

int64_t numbers_with_prime_divisor_count_not_two(
    const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    if (length != 1 || input[0] < 1 || input[0] > MAX_LIMIT) return -1;

    const size_t limit = (size_t)input[0];
    uint16_t divisor_counts[MAX_LIMIT] = {0};
    for (size_t divisor = 1; divisor < limit; ++divisor) {
        for (size_t multiple = divisor; multiple < limit; multiple += divisor)
            ++divisor_counts[multiple];
    }

    size_t selected_count = 0;
    for (size_t n = 1; n < limit; ++n) {
        const uint16_t count = divisor_counts[n];
        if (count != 2 && is_prime_count(count)) ++selected_count;
    }
    const size_t output_bytes = selected_count * 8;
    if (output == NULL || capacity < output_bytes) return -2;

    size_t output_index = 0;
    for (size_t n = 1; n < limit; ++n) {
        const uint16_t count = divisor_counts[n];
        if (count != 2 && is_prime_count(count)) {
            store_i64(output, output_index * 8, (int64_t)n);
            ++output_index;
        }
    }
    return (int64_t)output_bytes;
}
