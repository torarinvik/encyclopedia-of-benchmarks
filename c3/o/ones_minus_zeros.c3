module ones_minus_zeros;

const MAX_CELLS = 100000;
const MAX_DIMENSION = 100000;

fn long read_count(char* output, usz cell) {
    usz position = 4 * cell;
    long value = ((long)output[position]) & 255;
    value |= (((long)output[position + 1]) & 255) << 8;
    value |= (((long)output[position + 2]) & 255) << 16;
    value |= (((long)output[position + 3]) & 255) << 24;
    return value;
}

fn void write_i32_le(char* output, usz cell, long value) {
    long encoded = value;
    if (encoded < 0) encoded += 4294967296;
    usz position = 4 * cell;
    output[position] = (char)(encoded & 255);
    output[position + 1] = (char)((encoded >> 8) & 255);
    output[position + 2] = (char)((encoded >> 16) & 255);
    output[position + 3] = (char)((encoded >> 24) & 255);
}

fn long ones_minus_zeros(long* values, usz length, char* output, usz output_capacity)
    @export("ones_minus_zeros")
{
    if (values == null || length < 2 || values[0] < 1 || values[0] > MAX_DIMENSION ||
        values[1] < 1 || values[1] > MAX_DIMENSION) return -1;
    usz rows = (usz)values[0];
    usz columns = (usz)values[1];
    if (rows > MAX_CELLS / columns) return -1;
    usz cells = rows * columns;
    if (length != 2 + cells) return -1;
    for (usz cell = 0; cell < cells; cell++) {
        if (values[2 + cell] != 0 && values[2 + cell] != 1) return -1;
    }
    usz required = 4 * cells;
    if (output == null || output_capacity < required) return -2;
    for (usz byte = 0; byte < required; byte++) output[byte] = 0;

    long row_zero_ones = 0;
    long column_zero_ones = 0;
    for (usz row = 0; row < rows; row++) {
        for (usz column = 0; column < columns; column++) {
            if (values[2 + row * columns + column] == 0) continue;
            if (row == 0) { row_zero_ones++; }
            else {
                usz slot = row * columns;
                write_i32_le(output, slot, read_count(output, slot) + 1);
            }
            if (column == 0) { column_zero_ones++; }
            else { write_i32_le(output, column, read_count(output, column) + 1); }
        }
    }
    for (usz row = rows; row > 1; row--) {
        usz current_row = row - 1;
        usz row_slot = current_row * columns;
        long row_ones = read_count(output, row_slot);
        for (usz column = 0; column < columns; column++) {
            long column_ones = column == 0 ? column_zero_ones : read_count(output, column);
            long difference = 2 * row_ones + 2 * column_ones - (long)rows - (long)columns;
            write_i32_le(output, row_slot + column, difference);
        }
    }
    for (usz column = 0; column < columns; column++) {
        long column_ones = column == 0 ? column_zero_ones : read_count(output, column);
        long difference = 2 * row_zero_ones + 2 * column_ones - (long)rows - (long)columns;
        write_i32_le(output, column, difference);
    }
    return (long)cells;
}
