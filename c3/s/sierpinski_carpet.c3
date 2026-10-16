module sierpinski_carpet;

fn void write_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) output[offset + byte] = (char)((bits >> (8 * byte)) & 255);
}

fn bool is_filled(usz row, usz col) {
    while (row != 0 || col != 0) {
        if (row % 3 == 1 && col % 3 == 1) return false;
        row /= 3;
        col /= 3;
    }
    return true;
}

fn long sierpinski_carpet(long* input, usz length, char* output, usz capacity) @export("sierpinski_carpet") {
    if (input == null || length != 3) return -1;
    long depth = input[0], filled = input[1], hole = input[2];
    if (depth < 0 || depth > 4 || filled < 32 || filled > 126 || hole < 32 || hole > 126 || filled == hole) {
        return -1;
    }
    usz side = 1;
    for (long i = 0; i < depth; i++) side *= 3;
    usz needed = 8 + side * side + side - 1;
    if (output == null || capacity < needed) return -2;
    write_i64_le(output, 0, (long)side);
    usz out = 8;
    for (usz row = 0; row < side; row++) {
        for (usz col = 0; col < side; col++) {
            output[out++] = (char)(is_filled(row, col) ? filled : hole);
        }
        if (row + 1 < side) output[out++] = '\n';
    }
    return (long)needed;
}
