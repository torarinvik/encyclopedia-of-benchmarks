module mirror_of_matrix;

const usz MAX_PARSEABLE_INPUT_LENGTH = 259;
const usz MAX_DIMENSION = 16;

fn void store_i32_le(char* output, usz offset, int value) {
    uint bits = (uint)value;
    for (usz byte = 0; byte < 4; byte += 1)
        output[offset + byte] = (char)((bits >> (byte * 8)) & 255);
}

fn long mirror_of_matrix(long* values, usz length, char* output, usz capacity)
    @export("mirror_of_matrix") {
    if (values == null || length < 2 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    long raw_rows = values[0], raw_columns = values[1];
    if (raw_rows < 1 || raw_rows > (long)MAX_DIMENSION ||
        raw_columns < 1 || raw_columns > (long)MAX_DIMENSION) return -1;
    usz rows = (usz)raw_rows, columns = (usz)raw_columns;
    usz cell_count = rows * columns;
    if (length != 2 + cell_count) return -1;
    for (usz index = 0; index < cell_count; index += 1)
        if (values[2 + index] < -2147483648L || values[2 + index] > 2147483647L) return -1;

    usz byte_count = 4 * cell_count;
    if (output == null || capacity < byte_count) return -2;
    for (usz row = 0; row < rows; row += 1)
        for (usz column = 0; column < columns; column += 1)
            store_i32_le(output, 4 * (row * columns + column),
                         (int)values[2 + row * columns + (columns - 1 - column)]);
    return (long)byte_count;
}
