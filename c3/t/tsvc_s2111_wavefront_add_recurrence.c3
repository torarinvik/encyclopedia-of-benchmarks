module tsvc_s2111_wavefront_add_recurrence;

const usz MAX_SIDE = 8;
const usz MAX_PASSES = 4;
const usz MAX_CELLS = MAX_SIDE * MAX_SIDE;
const usz MAX_INPUT_LENGTH = 2 + MAX_CELLS;

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1)
        output[offset + byte] = (char)((bits >> (8 * byte)) & 255);
}

fn long tsvc_s2111_wavefront_add_recurrence(long* input, usz length, char* output,
        usz output_capacity) @export("tsvc_s2111_wavefront_add_recurrence") {
    if (input == null || length < 6 || length > MAX_INPUT_LENGTH) return -1;
    long side_raw = input[0], passes_raw = input[1];
    if (side_raw < 2 || side_raw > (long)MAX_SIDE || passes_raw < 1 || passes_raw > (long)MAX_PASSES) return -1;
    usz side = (usz)side_raw;
    usz cells = side * side;
    if (length != 2 + cells) return -1;

    long[MAX_CELLS] matrix;
    for (usz cell = 0; cell < cells; cell += 1) {
        long value = input[2 + cell];
        if (value < -8 || value > 8) return -1;
        matrix[cell] = value;
    }
    if (output == null || output_capacity < 8 * cells) return -2;

    for (usz pass = 0; pass < (usz)passes_raw; pass += 1) {
        for (usz row = 1; row < side; row += 1) {
            for (usz col = 1; col < side; col += 1) {
                matrix[row * side + col] = matrix[row * side + col - 1] + matrix[(row - 1) * side + col];
            }
        }
    }
    for (usz cell = 0; cell < cells; cell += 1) store_i64_le(output, 8 * cell, matrix[cell]);
    return (long)cells;
}
