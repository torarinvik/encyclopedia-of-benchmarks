module matrix_multiplication;

fn void store_i64_le(long value, char* output, usz offset) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) output[offset + byte] = (char)((bits >> (8 * byte)) & 255);
}

fn long matrix_multiplication(long* input, usz length, char* output, usz output_capacity) @export("matrix_multiplication") {
    if (input == null || length < 1) { return -2; }
    long dimension = input[0];
    if (dimension < 2 || dimension > 8) { return -2; }
    usz n = (usz)dimension;
    usz cells = n * n;
    if (length != 1 + 2 * cells) { return -2; }
    for (usz index = 0; index < 2 * cells; index++) {
        if (input[1 + index] < -1000 || input[1 + index] > 1000) { return -2; }
    }
    if (output == null || output_capacity < cells * 8) { return -3; }

    for (usz row = 0; row < n; row++) {
        for (usz column = 0; column < n; column++) {
            long sum = 0;
            for (usz index = 0; index < n; index++) {
                sum += input[1 + row * n + index] * input[1 + cells + index * n + column];
            }
            store_i64_le(sum, output, (row * n + column) * 8);
        }
    }
    return (long)cells;
}
