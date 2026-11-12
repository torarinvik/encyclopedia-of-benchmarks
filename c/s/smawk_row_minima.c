#include <stddef.h>
#include <stdint.h>

enum { MAX_ROWS = 16, MAX_COLUMNS = 16, MAX_INPUT_LENGTH = 260 };

static void smawk(const int64_t *matrix, size_t column_count,
                  int32_t *row_work, size_t row_offset, size_t row_count,
                  int32_t *column_work, size_t input_column_offset,
                  size_t input_column_count, size_t output_column_offset,
                  int32_t *minima)
{
    if (row_count == 0) return;
    if (row_count == 1) {
        const int32_t row = row_work[row_offset];
        int32_t best = column_work[input_column_offset];
        for (size_t j = 1; j < input_column_count; ++j) {
            const int32_t candidate = column_work[input_column_offset + j];
            if (matrix[(size_t)row * column_count + (size_t)candidate]
                < matrix[(size_t)row * column_count + (size_t)best]) best = candidate;
        }
        minima[row] = best;
        return;
    }

    size_t reduced_count = 0;
    for (size_t j = 0; j < input_column_count; ++j) {
        const int32_t candidate = column_work[input_column_offset + j];
        while (reduced_count > 0) {
            const int32_t comparison_row = row_work[row_offset + reduced_count - 1];
            const int32_t previous = column_work[output_column_offset + reduced_count - 1];
            if (matrix[(size_t)comparison_row * column_count + (size_t)candidate]
                < matrix[(size_t)comparison_row * column_count + (size_t)previous]) {
                --reduced_count;
            } else {
                break;
            }
        }
        if (reduced_count < row_count)
            column_work[output_column_offset + reduced_count++] = candidate;
    }

    const size_t odd_offset = row_offset + row_count;
    size_t odd_count = 0;
    for (size_t i = 1; i < row_count; i += 2)
        row_work[odd_offset + odd_count++] = row_work[row_offset + i];
    const size_t child_output_offset = output_column_offset + reduced_count;
    smawk(matrix, column_count, row_work, odd_offset, odd_count,
          column_work, output_column_offset, reduced_count,
          child_output_offset, minima);

    size_t start_cursor = 0;
    size_t end_cursor = 0;
    for (size_t i = 0; i < row_count; i += 2) {
        size_t start = 0;
        if (i > 0) {
            const int32_t target = minima[row_work[row_offset + i - 1]];
            while (start_cursor < reduced_count
                   && column_work[output_column_offset + start_cursor] != target) ++start_cursor;
            start = start_cursor < reduced_count ? start_cursor : reduced_count - 1;
        }
        size_t end = reduced_count - 1;
        if (i + 1 < row_count) {
            const int32_t target = minima[row_work[row_offset + i + 1]];
            if (end_cursor < start) end_cursor = start;
            while (end_cursor < reduced_count
                   && column_work[output_column_offset + end_cursor] != target) ++end_cursor;
            end = end_cursor < reduced_count ? end_cursor : reduced_count - 1;
        }
        const int32_t row = row_work[row_offset + i];
        int32_t best = column_work[output_column_offset + start];
        for (size_t j = start + 1; j <= end; ++j) {
            const int32_t candidate = column_work[output_column_offset + j];
            if (matrix[(size_t)row * column_count + (size_t)candidate]
                < matrix[(size_t)row * column_count + (size_t)best]) best = candidate;
        }
        minima[row] = best;
    }
}

static void store_i64_le(uint8_t *output, size_t offset, int64_t value)
{
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (byte * 8));
}

int64_t smawk_row_minima(const int64_t *input, size_t length,
                         uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 3 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > MAX_ROWS || input[1] < 1 || input[1] > MAX_COLUMNS) return -1;
    const size_t row_count = (size_t)input[0];
    const size_t column_count = (size_t)input[1];
    if (length != 2 + row_count * column_count) return -1;
    const int64_t *matrix = input + 2;

    int32_t row_work[2 * MAX_ROWS] = {0};
    int32_t column_work[3 * MAX_COLUMNS] = {0};
    int32_t minima[MAX_ROWS] = {0};
    for (size_t i = 0; i < row_count; ++i) row_work[i] = (int32_t)i;
    for (size_t j = 0; j < column_count; ++j) column_work[j] = (int32_t)j;
    smawk(matrix, column_count, row_work, 0, row_count,
          column_work, 0, column_count, MAX_COLUMNS, minima);

    uint8_t staged[8 * MAX_ROWS];
    const size_t output_bytes = row_count * 8;
    for (size_t i = 0; i < row_count; ++i) store_i64_le(staged, i * 8, minima[i]);
    if (output == NULL || capacity < output_bytes) return -2;
    for (size_t i = 0; i < output_bytes; ++i) output[i] = staged[i];
    return (int64_t)output_bytes;
}
