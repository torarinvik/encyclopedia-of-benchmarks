// Clean-room bounded profile of TSVC s2111; see package README.
#include <stddef.h>
#include <stdint.h>

#define MAX_SIDE 8
#define MAX_PASSES 4
#define MAX_CELLS (MAX_SIDE * MAX_SIDE)
#define MAX_INPUT_LENGTH (2 + MAX_CELLS)

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t tsvc_s2111_wavefront_add_recurrence(const int64_t *input, size_t length,
                                             uint8_t *output, size_t output_capacity) {
    if (input == NULL || length < 6 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t side_raw = input[0], passes_raw = input[1];
    if (side_raw < 2 || side_raw > MAX_SIDE || passes_raw < 1 || passes_raw > MAX_PASSES) return -1;
    const size_t side = (size_t)side_raw, cells = side * side;
    if (length != 2 + cells) return -1;

    int64_t matrix[MAX_CELLS];
    for (size_t cell = 0; cell < cells; ++cell) {
        const int64_t value = input[2 + cell];
        if (value < -8 || value > 8) return -1;
        matrix[cell] = value;
    }
    if (output == NULL || output_capacity < 8 * cells) return -2;

    for (size_t pass = 0; pass < (size_t)passes_raw; ++pass) {
        for (size_t row = 1; row < side; ++row) {
            for (size_t col = 1; col < side; ++col) {
                matrix[row * side + col] = matrix[row * side + col - 1] +
                                           matrix[(row - 1) * side + col];
            }
        }
    }
    for (size_t cell = 0; cell < cells; ++cell) store_i64_le(output, 8 * cell, matrix[cell]);
    return (int64_t)cells;
}
