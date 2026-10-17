#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH INT64_C(64)
#define MAX_INPUT_LENGTH ((size_t)67)

static void put_i64_le(uint8_t *output, size_t offset, int64_t value)
{
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

static int is_removed(int64_t value, const int64_t *input, size_t n, size_t by)
{
    if (by == 0) return 1;
    const size_t suffix_start = n - by;
    for (size_t key = suffix_start; key < n; ++key) {
        if (value == input[2 + key]) return 1;
    }
    return 0;
}

int64_t shorten_vector(const int64_t *input, size_t length, uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t raw_n = input[0], raw_by = input[1];
    if (raw_n < 0 || raw_n > MAX_LENGTH || raw_by < 0 || raw_by > raw_n) return -1;
    const size_t n = (size_t)raw_n, by = (size_t)raw_by;
    if (length != 2 + n) return -1;
    for (size_t i = 0; i < n; ++i) {
        if (input[2 + i] < -1000000 || input[2 + i] > 1000000) return -1;
    }

    size_t survivor_count = 0;
    for (size_t i = 0; i < n; ++i) {
        if (!is_removed(input[2 + i], input, n, by)) ++survivor_count;
    }
    const size_t bytes = survivor_count * 8;
    if (output == NULL || capacity < bytes) return -2;

    size_t written = 0;
    for (size_t i = 0; i < n; ++i) {
        const int64_t value = input[2 + i];
        if (!is_removed(value, input, n, by)) put_i64_le(output, written++ * 8, value);
    }
    return (int64_t)bytes;
}
