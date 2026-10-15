module pascal_triangle_row;

// Compute one row of Pascal's triangle using in-place dynamic programming.
fn long pascal_triangle_row(long row_index, char* output, usz output_capacity) @export("pascal_triangle_row") {
    if (row_index < 0 || row_index > 33) return -1;
    usz count = (usz)row_index + 1;
    usz required = count * 4;
    if (output == null || output_capacity < required) return -2;

    uint[34] coefficients;
    for (usz column = 0; column < count; column++) {
        coefficients[column] = 1;
    }
    for (usz row = 2; row <= (usz)row_index; row++) {
        for (usz column = row - 1; column > 0; column--) {
            coefficients[column] += coefficients[column - 1];
        }
    }

    usz position = 0;
    for (usz column = 0; column < count; column++) {
        for (usz byte = 0; byte < 4; byte++) {
            output[position++] = (char)(coefficients[column] >> (byte * 8));
        }
    }
    return (long)position;
}
