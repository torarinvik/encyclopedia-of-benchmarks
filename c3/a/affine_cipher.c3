module affine_cipher;

const usz MAX_INPUT_VALUES = 612;
const long MAX_TEXT_LENGTH = 512;

fn long gcd_i64(long left, long right) {
    while (right != 0) {
        long remainder = left % right;
        left = right;
        right = remainder;
    }
    return left;
}

fn long inverse_mod(long value, long modulus) {
    for (long candidate = 1; candidate < modulus; candidate++) {
        if ((value * candidate) % modulus == 1) return candidate;
    }
    return -1;
}

fn long affine_cipher(long* values, usz length, char* output, usz output_capacity)
        @export("affine_cipher") {
    if (values == null || length < 7 || length > MAX_INPUT_VALUES) return -1;
    long mode = values[0];
    long key_a = values[1];
    long key_b = values[2];
    long alphabet_length_arg = values[3];
    if (mode < 0 || mode > 1 || alphabet_length_arg < 2 || alphabet_length_arg > 95) return -1;
    usz alphabet_length = (usz)alphabet_length_arg;
    usz text_length_index = 4 + alphabet_length;
    if (length <= text_length_index) return -1;
    long text_length_arg = values[text_length_index];
    if (key_a < 0 || key_a > 1000000 || key_b < 0 || key_b >= alphabet_length_arg ||
        text_length_arg < 0 || text_length_arg > MAX_TEXT_LENGTH ||
        length != text_length_index + 1 + (usz)text_length_arg ||
        gcd_i64(key_a, alphabet_length_arg) != 1) return -1;
    usz text_length = (usz)text_length_arg;

    long[128] positions;
    for (usz code = 0; code < 128; code++) positions[code] = -1;
    for (usz index = 0; index < alphabet_length; index++) {
        long symbol = values[4 + index];
        if (symbol < 32 || symbol > 126 || positions[(usz)symbol] != -1) return -1;
        positions[(usz)symbol] = (long)index;
    }
    for (usz index = 0; index < text_length; index++) {
        long symbol = values[text_length_index + 1 + index];
        if (symbol < 32 || symbol > 126 || positions[(usz)symbol] < 0) return -1;
    }
    if (text_length > output_capacity || (text_length != 0 && output == null)) return -2;

    long multiplier = key_a % alphabet_length_arg;
    long inverse = mode == 1 ? inverse_mod(multiplier, alphabet_length_arg) : 0;
    for (usz index = 0; index < text_length; index++) {
        long symbol = values[text_length_index + 1 + index];
        long position = positions[(usz)symbol];
        long mapped = mode == 0
            ? (position * multiplier + key_b) % alphabet_length_arg
            : (((position - key_b + alphabet_length_arg) % alphabet_length_arg) * inverse) % alphabet_length_arg;
        output[index] = (char)values[4 + (usz)mapped];
    }
    return (long)text_length;
}
