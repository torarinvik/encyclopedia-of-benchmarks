#include <stddef.h>
#include <stdint.h>

static void put_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t count_min_sketch_width_one_collision(const int64_t *input, size_t length,
                                             uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || length > 513) return -1;
    const int64_t count_value = input[0];
    if (count_value < 0 || count_value > 256 || length != 1 + (size_t)count_value * 2) return -1;
    const size_t count = (size_t)count_value;
    size_t queries = 0;
    for (size_t i = 0; i < count; ++i) {
        const int64_t operation = input[1 + 2 * i];
        const int64_t key = input[2 + 2 * i];
        if ((operation != 0 && operation != 1) || key < -1000000 || key > 1000000) return -1;
        if (operation == 1) ++queries;
    }
    const size_t required = queries * 8;
    if (capacity < required || (required > 0 && output == NULL)) return -2;
    int64_t inserts = 0;
    size_t output_offset = 0;
    for (size_t i = 0; i < count; ++i) {
        if (input[1 + 2 * i] == 0) ++inserts;
        else { put_i64_le(output, output_offset, inserts); output_offset += 8; }
    }
    return (int64_t)required;
}
