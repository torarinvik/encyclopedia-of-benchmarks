module smawk_row_minima;

const usz MAX_ROWS = 16;
const usz MAX_COLUMNS = 16;
const usz MAX_INPUT_LENGTH = 260;

fn void smawk(long* matrix, usz column_count,
              int* row_work, usz row_offset, usz row_count,
              int* column_work, usz input_column_offset, usz input_column_count,
              usz output_column_offset, int* minima) {
    if (row_count == 0) return;
    if (row_count == 1) {
        int row = row_work[row_offset];
        int best = column_work[input_column_offset];
        for (usz j = 1; j < input_column_count; ++j) {
            int candidate = column_work[input_column_offset + j];
            if (matrix[(usz)row * column_count + (usz)candidate]
                < matrix[(usz)row * column_count + (usz)best]) best = candidate;
        }
        minima[row] = best;
        return;
    }

    usz reduced_count = 0;
    for (usz j = 0; j < input_column_count; ++j) {
        int candidate = column_work[input_column_offset + j];
        while (reduced_count > 0) {
            int comparison_row = row_work[row_offset + reduced_count - 1];
            int previous = column_work[output_column_offset + reduced_count - 1];
            if (matrix[(usz)comparison_row * column_count + (usz)candidate]
                < matrix[(usz)comparison_row * column_count + (usz)previous]) --reduced_count;
            else break;
        }
        if (reduced_count < row_count)
            column_work[output_column_offset + reduced_count++] = candidate;
    }

    usz odd_offset = row_offset + row_count;
    usz odd_count = 0;
    for (usz i = 1; i < row_count; i += 2)
        row_work[odd_offset + odd_count++] = row_work[row_offset + i];
    usz child_output_offset = output_column_offset + reduced_count;
    smawk(matrix, column_count, row_work, odd_offset, odd_count,
          column_work, output_column_offset, reduced_count, child_output_offset, minima);

    usz start_cursor = 0;
    usz end_cursor = 0;
    for (usz i = 0; i < row_count; i += 2) {
        usz start = 0;
        if (i > 0) {
            int target = minima[row_work[row_offset + i - 1]];
            while (start_cursor < reduced_count
                   && column_work[output_column_offset + start_cursor] != target) ++start_cursor;
            start = start_cursor < reduced_count ? start_cursor : reduced_count - 1;
        }
        usz end = reduced_count - 1;
        if (i + 1 < row_count) {
            int target = minima[row_work[row_offset + i + 1]];
            if (end_cursor < start) end_cursor = start;
            while (end_cursor < reduced_count
                   && column_work[output_column_offset + end_cursor] != target) ++end_cursor;
            end = end_cursor < reduced_count ? end_cursor : reduced_count - 1;
        }
        int row = row_work[row_offset + i];
        int best = column_work[output_column_offset + start];
        for (usz j = start + 1; j <= end; ++j) {
            int candidate = column_work[output_column_offset + j];
            if (matrix[(usz)row * column_count + (usz)candidate]
                < matrix[(usz)row * column_count + (usz)best]) best = candidate;
        }
        minima[row] = best;
    }
}

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; ++byte) output[offset + byte] = (char)(bits >> (byte * 8));
}

fn long smawk_row_minima(long* input, usz length, char* output, usz capacity)
        @export("smawk_row_minima") {
    if (input == null || length < 3 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > (long)MAX_ROWS
        || input[1] < 1 || input[1] > (long)MAX_COLUMNS) return -1;
    usz row_count = (usz)input[0];
    usz column_count = (usz)input[1];
    if (length != 2 + row_count * column_count) return -1;

    int[2 * MAX_ROWS] row_work;
    int[3 * MAX_COLUMNS] column_work;
    int[MAX_ROWS] minima;
    for (usz i = 0; i < row_count; ++i) row_work[i] = (int)i;
    for (usz j = 0; j < column_count; ++j) column_work[j] = (int)j;
    smawk(&input[2], column_count, &row_work[0], 0, row_count,
          &column_work[0], 0, column_count, MAX_COLUMNS, &minima[0]);

    char[8 * MAX_ROWS] staged;
    usz output_bytes = row_count * 8;
    for (usz i = 0; i < row_count; ++i) store_i64_le(&staged[0], i * 8, (long)minima[i]);
    if (output == null || capacity < output_bytes) return -2;
    for (usz i = 0; i < output_bytes; ++i) output[i] = staged[i];
    return (long)output_bytes;
}
