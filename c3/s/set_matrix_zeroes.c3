module set_matrix_zeroes;

const long MAX_DIMENSION = 8;
const usz MAX_INPUT_LENGTH = 67;
const usz MAX_CELLS = 64;
const long MIN_CELL = -1000000;
const long MAX_CELL = 1000000;

fn void write_i64_le(char* output, usz position, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) output[position + byte] = (char)(bits >> (8 * byte));
}

fn long set_matrix_zeroes(long* input, usz length, char* output, usz capacity) @export("set_matrix_zeroes") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    long rows_value = input[0], columns_value = input[1];
    if (rows_value < 1 || rows_value > MAX_DIMENSION || columns_value < 1 || columns_value > MAX_DIMENSION) return -1;
    usz rows = (usz)rows_value, columns = (usz)columns_value;
    usz cells = rows * columns;
    if (length != 2 + cells) return -1;

    long[MAX_CELLS] matrix;
    for (usz index = 0; index < cells; index++) {
        long value = input[2 + index];
        if (value < MIN_CELL || value > MAX_CELL) return -1;
        matrix[index] = value;
    }

    usz bytes = cells * 8;
    if (output == null || capacity < bytes) return -2;

    bool first_column_zero = false;
    for (usz row = 0; row < rows; row++) {
        if (matrix[row * columns] == 0) first_column_zero = true;
        for (usz column = 1; column < columns; column++) {
            if (matrix[row * columns + column] == 0) {
                matrix[row * columns] = 0;
                matrix[column] = 0;
            }
        }
    }
    for (usz row = 1; row < rows; row++) {
        for (usz column = 1; column < columns; column++) {
            if (matrix[row * columns] == 0 || matrix[column] == 0) matrix[row * columns + column] = 0;
        }
    }
    if (matrix[0] == 0) {
        for (usz column = 0; column < columns; column++) matrix[column] = 0;
    }
    if (first_column_zero) {
        for (usz row = 0; row < rows; row++) matrix[row * columns] = 0;
    }

    for (usz index = 0; index < cells; index++) write_i64_le(output, index * 8, matrix[index]);
    return (long)bytes;
}
