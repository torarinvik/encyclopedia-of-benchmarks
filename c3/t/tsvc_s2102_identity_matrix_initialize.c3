module tsvc_s2102_identity_matrix_initialize;

const usz MAX_SIDE = 8;
const usz MAX_PASSES = 8;
const usz MAX_CELLS = MAX_SIDE * MAX_SIDE;

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1)
        output[offset + byte] = (char)((bits >> (8 * byte)) & 255);
}

fn long tsvc_s2102_identity_matrix_initialize(long* input, usz length, char* output,
        usz output_capacity) @export("tsvc_s2102_identity_matrix_initialize") {
    if (input == null || length != 2) return -1;
    long side_raw = input[0], passes_raw = input[1];
    if (side_raw < 1 || side_raw > (long)MAX_SIDE || passes_raw < 1 || passes_raw > (long)MAX_PASSES) return -1;
    usz side = (usz)side_raw;
    usz cells = side * side;
    if (output == null || output_capacity < 8 * cells) return -2;

    long[MAX_CELLS] matrix;
    for (usz pass = 0; pass < (usz)passes_raw; pass += 1) {
        for (usz col = 0; col < side; col += 1) {
            for (usz row = 0; row < side; row += 1) matrix[row * side + col] = 0;
            matrix[col * side + col] = 1;
        }
    }
    for (usz cell = 0; cell < cells; cell += 1) store_i64_le(output, 8 * cell, matrix[cell]);
    return (long)cells;
}
