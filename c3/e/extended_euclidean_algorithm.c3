module extended_euclidean_algorithm;

// Iterative extended Euclid for positive signed-32-bit inputs.
fn usz store_i32(long value, char* output, usz position) {
    ulong bits;
    if (value < 0) { bits = 4294967296 - (ulong)(-value); }
    else { bits = (ulong)value; }
    for (usz byte = 0; byte < 4; byte++) {
        output[position++] = (char)(bits % 256);
        bits /= 256;
    }
    return position;
}

fn long extended_euclidean_algorithm(long* input, usz length, char* output, usz output_capacity)
        @export("extended_euclidean_algorithm") {
    if (length != 2 || input[0] < 1 || input[0] > 2147483647 ||
        input[1] < 1 || input[1] > 2147483647) return -1;
    if (output_capacity < 12) return -2;

    long old_r = input[0];
    long remainder = input[1];
    long old_x = 1;
    long x = 0;
    long old_y = 0;
    long y = 1;
    while (remainder != 0) {
        long quotient = old_r / remainder;
        long next_r = old_r - quotient * remainder;
        old_r = remainder;
        remainder = next_r;
        long next_x = old_x - quotient * x;
        old_x = x;
        x = next_x;
        long next_y = old_y - quotient * y;
        old_y = y;
        y = next_y;
    }
    if (old_r > 2147483647 || old_x < -2147483648 || old_x > 2147483647 ||
        old_y < -2147483648 || old_y > 2147483647) return -1;
    usz written = 0;
    written = store_i32(old_r, output, written);
    written = store_i32(old_x, output, written);
    written = store_i32(old_y, output, written);
    return written == 12 ? 3 : -1;
}
