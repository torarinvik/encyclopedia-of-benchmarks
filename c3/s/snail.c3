module snail;

const usz MAX_CELLS = 256;
const usz MAX_INPUT_LENGTH = 259;

fn void snail_put_i32_le(char* output, usz index, int value) {
    uint bits = (uint)value;
    usz offset = index * 4;
    for (usz byte = 0; byte < 4; byte += 1) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long snail(int* values, usz length, char* output, usz output_capacity) @export("snail") {
    if (values == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    int rows_value = values[0], columns_value = values[1];
    if (rows_value < 0 || rows_value > 16 || columns_value < 0 || columns_value > 16) return -1;
    if (rows_value == 0 && columns_value != 0) return -1;
    if (columns_value == 1 && rows_value != 1) return -1;

    usz rows = (usz)rows_value, columns = (usz)columns_value;
    usz cell_count = rows * columns;
    if (length != 2 + cell_count) return -1;

    usz required_bytes = 4 * cell_count;
    if (output == null || output_capacity < required_bytes) return -2;
    if (cell_count == 0) return 0;

    int matrix[MAX_CELLS] = {0};
    for (usz index = 0; index < cell_count; index += 1)
        matrix[index] = values[2 + index];

    int top = 0, bottom = (int)rows - 1, left = 0, right = (int)columns - 1;
    usz written = 0;
    while (top <= bottom && left <= right) {
        for (int column = left; column <= right; column += 1)
            snail_put_i32_le(output, written++, matrix[(usz)top * columns + (usz)column]);
        top += 1;

        for (int row = top; row <= bottom; row += 1)
            snail_put_i32_le(output, written++, matrix[(usz)row * columns + (usz)right]);
        right -= 1;

        if (top <= bottom && left <= right) {
            for (int column = right; column >= left; column -= 1)
                snail_put_i32_le(output, written++, matrix[(usz)bottom * columns + (usz)column]);
            bottom -= 1;
        }

        if (top <= bottom && left <= right) {
            for (int row = bottom; row >= top; row -= 1)
                snail_put_i32_le(output, written++, matrix[(usz)row * columns + (usz)left]);
            left += 1;
        }
    }
    return (long)required_bytes;
}
