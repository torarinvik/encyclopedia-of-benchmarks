module spiral_print;

const usz MAX_CELLS = 256;
const usz MAX_INPUT_LENGTH = 259;

fn void spiral_print_put_i64_le(uint8* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (uint8)(bits & 255);
        bits >>= 8;
    }
}

fn long spiral_print(long* input, usz length, uint8* output, usz capacity) @export("spiral_print") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    long rows_value = input[0], columns_value = input[1];
    if (rows_value < 1 || rows_value > 16 || columns_value < 2 || columns_value > 16) return -1;

    usz rows = (usz)rows_value, columns = (usz)columns_value;
    usz cell_count = rows * columns;
    if (length != 2 + cell_count) return -1;

    long matrix[MAX_CELLS] = {0};
    for (usz index = 0; index < cell_count; index++) {
        long value = input[2 + index];
        if (value < -2147483648 || value > 2147483647) return -1;
        matrix[index] = value;
    }

    usz required_bytes = 8 * cell_count;
    if (output == null || capacity < required_bytes) return -2;

    long order[MAX_CELLS] = {0};
    usz order_length = 0;
    usz top = 0, bottom = rows - 1, left = 0, right = columns - 1;
    while (top <= bottom && left <= right) {
        for (usz column = left; column <= right; column++) {
            order[order_length++] = matrix[top * columns + column];
        }
        top++;

        for (usz row = top; row <= bottom; row++) {
            order[order_length++] = matrix[row * columns + right];
        }
        right--;

        if (top <= bottom && left <= right) {
            usz column = right;
            while (true) {
                order[order_length++] = matrix[bottom * columns + column];
                if (column == left) break;
                column--;
            }
            bottom--;
        }

        if (top <= bottom && left <= right) {
            usz row = bottom;
            while (true) {
                order[order_length++] = matrix[row * columns + left];
                if (row == top) break;
                row--;
            }
            left++;
        }
    }

    for (usz index = 0; index < order_length; index++) {
        spiral_print_put_i64_le(output, 8 * index, order[index]);
    }
    return (long)required_bytes;
}
