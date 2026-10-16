module hex_to_oct;

const long INVALID_RESULT = -2147483649;

fn int hex_digit(long code) {
    if (code >= '0' && code <= '9') return (int)(code - '0');
    if (code >= 'A' && code <= 'F') return (int)(code - 'A' + 10);
    if (code >= 'a' && code <= 'f') return (int)(code - 'a' + 10);
    return -1;
}

fn long signed_i32(uint bits) {
    if (bits <= 2147483647u) return (long)bits;
    return (long)(ulong)bits - 4294967296L;
}

fn long hex_to_oct(long* input, usz length) @export("hex_to_oct") {
    if (length > 8 || (length != 0 && input == null)) return INVALID_RESULT;
    uint decimal_bits = 0;
    for (usz index = 0; index < length; index++) {
        int digit = hex_digit(input[index]);
        if (digit < 0) return INVALID_RESULT;
        decimal_bits = decimal_bits * 16u + (uint)digit;
    }
    long decimal = signed_i32(decimal_bits);
    if (decimal <= 0) return 0;

    uint octal_bits = 0;
    uint place_value = 1;
    while (decimal > 0) {
        octal_bits += (uint)(decimal % 8) * place_value;
        decimal /= 8;
        place_value *= 10u;
    }
    return signed_i32(octal_bits);
}
