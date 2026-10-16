#include <stddef.h>
#include <stdint.h>

#define MAX_OUTPUT_BYTES 6649

static void write_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
    }
}

static int is_filled(size_t row, size_t col) {
    while (row != 0 || col != 0) {
        if (row % 3 == 1 && col % 3 == 1) return 0;
        row /= 3;
        col /= 3;
    }
    return 1;
}

int64_t sierpinski_carpet(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length != 3) return -1;
    const int64_t depth = input[0], filled = input[1], hole = input[2];
    if (depth < 0 || depth > 4 || filled < 32 || filled > 126 ||
        hole < 32 || hole > 126 || filled == hole) {
        return -1;
    }
    size_t side = 1;
    for (int64_t i = 0; i < depth; ++i) side *= 3;
    const size_t needed = 8 + side * side + side - 1;
    if (needed > MAX_OUTPUT_BYTES) return -1;
    if (output == NULL || capacity < needed) return -2;

    write_i64_le(output, 0, (int64_t)side);
    size_t out = 8;
    for (size_t row = 0; row < side; ++row) {
        for (size_t col = 0; col < side; ++col) {
            output[out++] = (uint8_t)(is_filled(row, col) ? filled : hole);
        }
        if (row + 1 < side) output[out++] = (uint8_t)'\n';
    }
    return (int64_t)needed;
}
