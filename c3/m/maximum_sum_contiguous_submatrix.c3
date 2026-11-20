module maximum_sum_contiguous_submatrix;

const long MAX_PARSEABLE_INPUT_LENGTH = 67;
const usz MAX_OUTPUT_BYTES = 8;

fn void write_i64_le(char* output, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[byte] = (char)((bits >> (byte * 8)) & 255);
    }
}

fn long maximum_sum_contiguous_submatrix(long* input, usz length,
        char* output, usz output_capacity) @export("maximum_sum_contiguous_submatrix") {
    if (input == null || length < 2 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    long rows_value = input[0];
    long columns_value = input[1];
    if (rows_value < 1 || rows_value > 8 || columns_value < 1 || columns_value > 8) return -1;
    usz rows = (usz)rows_value;
    usz columns = (usz)columns_value;
    usz cells = rows * columns;
    if (length != 2 + cells) return -1;
    for (usz index = 0; index < cells; index++) {
        if (input[index + 2] < -1000 || input[index + 2] > 1000) return -1;
    }

    long best = -64001;
    long[8] column_sums = {};
    for (usz top = 0; top < rows; top++) {
        for (usz column = 0; column < columns; column++) column_sums[column] = 0;
        for (usz bottom = top; bottom < rows; bottom++) {
            usz row_offset = 2 + bottom * columns;
            for (usz column = 0; column < columns; column++) {
                column_sums[column] += input[row_offset + column];
            }
            long current = column_sums[0];
            if (current > best) best = current;
            for (usz column = 1; column < columns; column++) {
                current = current < 0 ? column_sums[column] : current + column_sums[column];
                if (current > best) best = current;
            }
        }
    }
    if (output == null || output_capacity < MAX_OUTPUT_BYTES) return -2;
    write_i64_le(output, best);
    return (long)MAX_OUTPUT_BYTES;
}
