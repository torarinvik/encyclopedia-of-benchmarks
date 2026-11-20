#include <math.h>
#include <stddef.h>
#include <stdint.h>
#include <string.h>

enum { MAX_N = 16, MAX_NONZER = 4, MAX_SUPPORT = 5, MAX_TRIPLETS = 416 };
static const int64_t max_value_micro = INT64_C(1000000);
static const int64_t max_shift_micro = INT64_C(10000000);
static const double scale_micro = 1000000.0;
static const double rcond = 0.1;

static void write_u64_le(uint8_t *output, size_t offset, uint64_t value) {
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(value >> (8 * byte));
}

static void write_f64_le(uint8_t *output, size_t offset, double value) {
    uint64_t bits;
    memcpy(&bits, &value, sizeof(bits));
    write_u64_le(output, offset, bits);
}

static int valid(const int64_t *v, size_t length, size_t *n_out,
                 size_t *nonzer_out) {
    if (v == NULL || length < 3 || length > 3 + 2 * MAX_N * MAX_NONZER)
        return 0;
    if (v[0] < 2 || v[0] > MAX_N || v[1] < 1 || v[1] > MAX_NONZER ||
        v[2] < 0 || v[2] > max_shift_micro)
        return 0;
    const size_t n = (size_t)v[0], nonzer = (size_t)v[1];
    if (length != 3 + 2 * n * nonzer) return 0;
    size_t cursor = 3;
    for (size_t vector = 0; vector < n; ++vector) {
        uint32_t seen = 0;
        for (size_t entry = 0; entry < nonzer; ++entry) {
            const int64_t coordinate = v[cursor++];
            const int64_t value = v[cursor++];
            if (coordinate < 0 || coordinate >= (int64_t)n || value == 0 ||
                value < -max_value_micro || value > max_value_micro)
                return 0;
            const uint32_t bit = UINT32_C(1) << (unsigned)coordinate;
            if ((seen & bit) != 0) return 0;
            seen |= bit;
        }
    }
    *n_out = n;
    *nonzer_out = nonzer;
    return 1;
}

int64_t npb_cg_sparse_outer_product_assembly(
        const int64_t *values, size_t length, uint8_t *output,
        size_t output_capacity) {
    size_t n, nonzer;
    if (!valid(values, length, &n, &nonzer)) return -1;

    uint8_t raw_rows[MAX_TRIPLETS], raw_columns[MAX_TRIPLETS];
    double raw_values[MAX_TRIPLETS];
    size_t raw_count = 0, cursor = 3;
    for (size_t vector = 0; vector < n; ++vector) {
        uint8_t coordinates[MAX_SUPPORT];
        double vector_values[MAX_SUPPORT];
        size_t support_count = nonzer;
        int has_anchor = 0;
        for (size_t entry = 0; entry < nonzer; ++entry) {
            const size_t coordinate = (size_t)values[cursor++];
            coordinates[entry] = (uint8_t)coordinate;
            vector_values[entry] = (double)values[cursor++] / scale_micro;
            if (coordinate == vector) {
                vector_values[entry] = 0.5;
                has_anchor = 1;
            }
        }
        if (!has_anchor) {
            coordinates[support_count] = (uint8_t)vector;
            vector_values[support_count++] = 0.5;
        }
        const double weight = vector == 0 ? 1.0 :
            (vector + 1 == n ? rcond : pow(rcond, (double)vector / (double)(n - 1)));
        for (size_t column_slot = 0; column_slot < support_count; ++column_slot) {
            const double scaled_column = weight * vector_values[column_slot];
            for (size_t row_slot = 0; row_slot < support_count; ++row_slot) {
                raw_rows[raw_count] = coordinates[row_slot];
                raw_columns[raw_count] = coordinates[column_slot];
                raw_values[raw_count++] = vector_values[row_slot] * scaled_column;
            }
        }
    }
    const double diagonal_addend = rcond - (double)values[2] / scale_micro;
    for (size_t diagonal = 0; diagonal < n; ++diagonal) {
        raw_rows[raw_count] = (uint8_t)diagonal;
        raw_columns[raw_count] = (uint8_t)diagonal;
        raw_values[raw_count++] = diagonal_addend;
    }

    int64_t column_pointers[MAX_N + 1];
    uint8_t row_indices[MAX_N * MAX_N];
    double matrix_values[MAX_N * MAX_N];
    size_t nnz = 0;
    for (size_t column = 0; column < n; ++column) {
        column_pointers[column] = (int64_t)nnz;
        for (size_t row = 0; row < n; ++row) {
            double sum = 0.0;
            int touched = 0;
            for (size_t triple = 0; triple < raw_count; ++triple) {
                if (raw_rows[triple] == row && raw_columns[triple] == column) {
                    sum += raw_values[triple];
                    touched = 1;
                }
            }
            if (touched) {
                row_indices[nnz] = (uint8_t)row;
                matrix_values[nnz++] = sum;
            }
        }
    }
    column_pointers[n] = (int64_t)nnz;
    const size_t required = 8 * (2 + (n + 1) + 2 * nnz);
    if (output == NULL || output_capacity < required) return -2;

    size_t offset = 0;
    write_f64_le(output, offset, (double)n); offset += 8;
    write_f64_le(output, offset, (double)nnz); offset += 8;
    for (size_t i = 0; i <= n; ++i, offset += 8)
        write_f64_le(output, offset, (double)column_pointers[i]);
    for (size_t i = 0; i < nnz; ++i, offset += 8)
        write_f64_le(output, offset, (double)row_indices[i]);
    for (size_t i = 0; i < nnz; ++i, offset += 8)
        write_f64_le(output, offset, matrix_values[i]);
    return (int64_t)required;
}
