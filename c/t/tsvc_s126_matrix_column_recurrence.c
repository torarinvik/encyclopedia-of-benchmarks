/* Clean-room port of TSVC s126; provenance and rights are in the package README. */
#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 6, MAX_CELLS = MAX_N * MAX_N, MAX_INPUT_LENGTH = 1 + 3 * MAX_CELLS };

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & 0xffu);
        bits >>= 8;
    }
}

int64_t tsvc_s126_matrix_column_recurrence(const int64_t *input, size_t length,
                                           uint8_t *output, size_t capacity) {
    if (input == NULL || length < 13 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 2 || input[0] > MAX_N) return -1;
    const size_t n = (size_t)input[0], cells = n * n;
    if (length != 1 + 3 * cells) return -1;
    int64_t coefficients[MAX_CELLS], c_matrix[MAX_CELLS], b_matrix[MAX_CELLS];
    for (size_t i = 0; i < cells; ++i) {
        coefficients[i] = input[1 + i];
        c_matrix[i] = input[1 + cells + i];
        b_matrix[i] = input[1 + 2 * cells + i];
        if (coefficients[i] < -100 || coefficients[i] > 100 ||
            c_matrix[i] < -100 || c_matrix[i] > 100 ||
            b_matrix[i] < -100 || b_matrix[i] > 100) return -1;
    }
    const size_t output_bytes = 8 * cells;
    if (output == NULL || capacity < output_bytes) return -2;
    size_t k = 1;
    for (size_t i = 0; i < n; ++i) {
        for (size_t j = 1; j < n; ++j) {
            const size_t target = j * n + i;
            b_matrix[target] = b_matrix[target - n] + coefficients[k - 1] * c_matrix[target];
            ++k;
        }
        ++k;
    }
    for (size_t i = 0; i < cells; ++i) store_i64_le(output, 8 * i, b_matrix[i]);
    return (int64_t)cells;
}
