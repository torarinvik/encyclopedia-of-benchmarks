#include <stddef.h>
#include <stdint.h>

#define MAX_CAPACITY 16
#define MAX_REFERENCES 64

static void put_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t least_recently_used(const int64_t *input, size_t length, uint8_t *output, size_t output_capacity) {
    if (input == NULL || length < 2 || length > 2 + MAX_REFERENCES) return -1;
    int64_t capacity_value = input[0], count_value = input[1];
    if (capacity_value < 1 || capacity_value > MAX_CAPACITY || count_value < 0 || count_value > MAX_REFERENCES) return -1;
    size_t cache_capacity = (size_t)capacity_value, references = (size_t)count_value;
    if (length != 2 + references) return -1;
    for (size_t i = 0; i < references; ++i) if (input[2 + i] < INT32_MIN || input[2 + i] > INT32_MAX) return -1;

    int64_t keys[MAX_CAPACITY];
    size_t count = 0;
    for (size_t i = 0; i < references; ++i) {
        int64_t key = input[2 + i];
        size_t found = count;
        for (size_t j = 0; j < count; ++j) if (keys[j] == key) { found = j; break; }
        if (found < count) {
            for (size_t j = found; j + 1 < count; ++j) keys[j] = keys[j + 1];
            --count;
        } else if (count == cache_capacity) --count;
        for (size_t j = count; j > 0; --j) keys[j] = keys[j - 1];
        keys[0] = key;
        ++count;
    }

    size_t elements = count + 1, required = elements * 8;
    if (output == NULL || output_capacity < required) return -2;
    put_i64_le(output, 0, (int64_t)count);
    for (size_t i = 0; i < count; ++i) put_i64_le(output, 8 * (i + 1), keys[i]);
    return (int64_t)elements;
}
