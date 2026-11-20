module hilbert_curve_index_encode;

const long MAX_ORDER = 8;

fn long hilbert_index(long order, long x, long y) {
    long current_x = x, current_y = y, distance = 0;
    for (long bit_index = order - 1; bit_index >= 0; bit_index--) {
        long bit = 1 << bit_index;
        long x_bit = (current_x & bit) != 0 ? 1 : 0;
        long y_bit = (current_y & bit) != 0 ? 1 : 0;
        distance += bit * bit * ((3 * x_bit) ^ y_bit);
        long mask = bit - 1;
        long low_x = current_x & mask;
        long low_y = current_y & mask;
        if (y_bit == 0) {
            if (x_bit != 0) {
                low_x = mask - low_x;
                low_y = mask - low_y;
            }
            current_x = low_y;
            current_y = low_x;
        } else {
            current_x = low_x;
            current_y = low_y;
        }
    }
    return distance;
}

fn void store_i64_le(char *output, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long hilbert_curve_index_encode(long *input, usz length, char *output,
                                   usz capacity)
    @export("hilbert_curve_index_encode") {
    if (input == null || length != 3) return -1;
    long order = input[0];
    if (order < 1 || order > MAX_ORDER) return -1;
    long side = 1 << order;
    long x = input[1], y = input[2];
    if (x < 0 || x >= side || y < 0 || y >= side) return -1;
    if (output == null || capacity < 8) return -2;
    store_i64_le(output, hilbert_index(order, x, y));
    return 8;
}
