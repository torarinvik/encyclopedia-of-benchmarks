// Clean-room bounded profile of TSVC s2102; see package README.
#include <stddef.h>
#include <stdint.h>

#define MAX_SIDE 8
#define MAX_PASSES 8
#define MAX_CELLS (MAX_SIDE * MAX_SIDE)

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t tsvc_s2102_identity_matrix_initialize(const int64_t *input, size_t length,
                                               uint8_t *output, size_t output_capacity) {
    if (input == NULL || length != 2) return -1;
    const int64_t side_raw = input[0], passes_raw = input[1];
    if (side_raw < 1 || side_raw > MAX_SIDE || passes_raw < 1 || passes_raw > MAX_PASSES) return -1;
    const size_t side = (size_t)side_raw, cells = side * side;
    if (output == NULL || output_capacity < 8 * cells) return -2;

    int64_t matrix[MAX_CELLS] = {0};
    for (size_t pass = 0; pass < (size_t)passes_raw; ++pass) {
        for (size_t col = 0; col < side; ++col) {
            for (size_t row = 0; row < side; ++row) matrix[row * side + col] = 0;
            matrix[col * side + col] = 1;
        }
    }
    for (size_t cell = 0; cell < cells; ++cell) store_i64_le(output, 8 * cell, matrix[cell]);
    return (int64_t)cells;
}
