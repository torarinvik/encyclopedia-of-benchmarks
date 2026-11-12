#include <stddef.h>
#include <stdint.h>

#define MAX_DIMENSION 64
#define MAX_INPUT_VALUES (3 + 2 * MAX_DIMENSION * MAX_DIMENSION)
#define MAX_OUTPUT_VALUES (MAX_DIMENSION * MAX_DIMENSION)

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t matrix_product_mod_2(const int64_t *input, size_t length,
                             uint8_t *output, size_t capacity) {
    if (input == NULL || length < 3 || length > MAX_INPUT_VALUES) return -1;
    const int64_t n_value = input[0], m_value = input[1], k_value = input[2];
    if (n_value < 1 || n_value > MAX_DIMENSION || m_value < 1 ||
        m_value > MAX_DIMENSION || k_value < 1 || k_value > MAX_DIMENSION) return -1;
    const size_t n = (size_t)n_value, m = (size_t)m_value, k = (size_t)k_value;
    const size_t a_length = n * m, b_length = m * k;
    if (length != 3 + a_length + b_length) return -1;

    uint64_t packed_b[MAX_DIMENSION] = {0};
    const size_t b_start = 3 + a_length;
    for (size_t inner = 0; inner < m; ++inner) {
        for (size_t column = 0; column < k; ++column) {
            const int64_t bit = input[b_start + inner * k + column];
            if (bit != 0 && bit != 1) return -1;
            packed_b[inner] |= (uint64_t)bit << column;
        }
    }

    int64_t staged[MAX_OUTPUT_VALUES];
    for (size_t row = 0; row < n; ++row) {
        uint64_t accumulator = 0;
        for (size_t inner = 0; inner < m; ++inner) {
            const int64_t bit = input[3 + row * m + inner];
            if (bit != 0 && bit != 1) return -1;
            if (bit == 1) accumulator ^= packed_b[inner];
        }
        for (size_t column = 0; column < k; ++column)
            staged[row * k + column] = (int64_t)((accumulator >> column) & 1u);
    }

    const size_t required = 8 * n * k;
    if (output == NULL || capacity < required) return -2;
    for (size_t index = 0; index < n * k; ++index)
        store_i64_le(output, 8 * index, staged[index]);
    return (int64_t)required;
}
