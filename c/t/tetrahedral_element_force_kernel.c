#include <stddef.h>
#include <stdint.h>

#define MAX_ELEMENTS 32
#define MAX_VALID_INPUT_LENGTH (3 + 12 * MAX_ELEMENTS)
#define MAX_INPUT_LENGTH (MAX_VALID_INPUT_LENGTH + 1)

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t tetrahedral_element_force_kernel(const int64_t *input, size_t length,
                                         uint8_t *output, size_t capacity) {
    if (input == NULL || length < 3 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t m_value = input[0], lambda = input[1], mu = input[2];
    if (m_value < 1 || m_value > MAX_ELEMENTS || lambda < 0 || lambda > 16 ||
        mu < 0 || mu > 16 || length != 3 + 12 * (size_t)m_value) return -1;
    const size_t m = (size_t)m_value;
    for (size_t i = 3; i < length; ++i)
        if (input[i] < -4 || input[i] > 4) return -1;

    const size_t required = 96 * m;
    if (output == NULL || capacity < required) return -2;

    for (size_t element = 0; element < m; ++element) {
        const int64_t *coordinates = input + 3 + 12 * element;
        int64_t f[3][3];
        for (size_t row = 0; row < 3; ++row)
            for (size_t column = 0; column < 3; ++column)
                f[row][column] = coordinates[3 * (column + 1) + row] - coordinates[row];

        const int64_t trace_delta = f[0][0] + f[1][1] + f[2][2] - 3;
        int64_t stress[3][3];
        for (size_t row = 0; row < 3; ++row) {
            for (size_t column = 0; column < 3; ++column) {
                const int64_t diagonal = row == column ? 1 : 0;
                stress[row][column] = lambda * trace_delta * diagonal +
                    mu * (f[row][column] + f[column][row] - 2 * diagonal);
            }
        }

        int64_t force[4][3];
        for (size_t axis = 0; axis < 3; ++axis) {
            force[0][axis] = stress[axis][0] + stress[axis][1] + stress[axis][2];
            for (size_t vertex = 1; vertex < 4; ++vertex)
                force[vertex][axis] = -stress[axis][vertex - 1];
        }
        for (size_t vertex = 0; vertex < 4; ++vertex)
            for (size_t axis = 0; axis < 3; ++axis)
                store_i64_le(output, 8 * (12 * element + 3 * vertex + axis),
                             force[vertex][axis]);
    }
    return (int64_t)required;
}
