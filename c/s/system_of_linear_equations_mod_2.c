#include <stddef.h>
#include <stdint.h>

#define MAX_N 32
#define MAX_M 32
#define MAX_INPUT_VALUES (2 + MAX_N * MAX_M + MAX_N)

static void store_u64_le(uint8_t *output, size_t offset, uint64_t value) {
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(value >> (8 * byte));
}

int64_t system_of_linear_equations_mod_2(const int64_t *input, size_t length,
                                         uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT_VALUES) return -1;
    const int64_t n_value = input[0];
    const int64_t m_value = input[1];
    if (n_value < 1 || n_value > MAX_N || m_value < 1 || m_value > MAX_M) return -1;
    const size_t n = (size_t)n_value;
    const size_t m = (size_t)m_value;
    if (length != 2 + n * m + n) return -1;

    uint64_t rows[MAX_N] = {0};
    uint8_t rhs[MAX_N] = {0};
    for (size_t row = 0; row < n; ++row) {
        for (size_t column = 0; column < m; ++column) {
            const int64_t bit = input[2 + row * m + column];
            if (bit != 0 && bit != 1) return -1;
            rows[row] |= (uint64_t)bit << column;
        }
        const int64_t bit = input[2 + n * m + row];
        if (bit != 0 && bit != 1) return -1;
        rhs[row] = (uint8_t)bit;
    }

    size_t pivot_columns[MAX_N] = {0};
    size_t pivot_row = 0;
    for (size_t column = 0; column < m; ++column) {
        size_t pivot = pivot_row;
        while (pivot < n && ((rows[pivot] >> column) & 1u) == 0) ++pivot;
        if (pivot == n) continue;
        uint64_t row_temporary = rows[pivot_row];
        rows[pivot_row] = rows[pivot];
        rows[pivot] = row_temporary;
        uint8_t rhs_temporary = rhs[pivot_row];
        rhs[pivot_row] = rhs[pivot];
        rhs[pivot] = rhs_temporary;
        for (size_t row = 0; row < n; ++row) {
            if (row != pivot_row && ((rows[row] >> column) & 1u) != 0) {
                rows[row] ^= rows[pivot_row];
                rhs[row] ^= rhs[pivot_row];
            }
        }
        pivot_columns[pivot_row++] = column;
    }

    for (size_t row = pivot_row; row < n; ++row)
        if (rows[row] == 0 && rhs[row] != 0) {
            if (output == NULL || capacity < 8) return -2;
            store_u64_le(output, 0, UINT64_MAX);
            return 8;
        }

    uint8_t is_pivot[MAX_M] = {0};
    for (size_t row = 0; row < pivot_row; ++row) is_pivot[pivot_columns[row]] = 1;
    const size_t nullity = m - pivot_row;
    const size_t output_bytes = 8 * (nullity + 2);
    if (output == NULL || capacity < output_bytes) return -2;

    uint64_t particular = 0;
    for (size_t row = 0; row < pivot_row; ++row)
        if (rhs[row] != 0) particular |= UINT64_C(1) << pivot_columns[row];
    store_u64_le(output, 0, (uint64_t)nullity);
    store_u64_le(output, 8, particular);
    size_t basis_index = 0;
    for (size_t free_column = 0; free_column < m; ++free_column) {
        if (is_pivot[free_column]) continue;
        uint64_t basis = UINT64_C(1) << free_column;
        for (size_t row = 0; row < pivot_row; ++row)
            if (((rows[row] >> free_column) & 1u) != 0)
                basis |= UINT64_C(1) << pivot_columns[row];
        store_u64_le(output, 16 + 8 * basis_index++, basis);
    }
    return (int64_t)output_bytes;
}
