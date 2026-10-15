module decimal_expansion;

fn void write_i64_le(char* output, usz offset, long value) {
    if (value == -1) {
        for (usz byte = 0; byte < 8; byte++) output[offset + byte] = (char)0xFF;
        return;
    }
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (char)((bits >> (8 * byte)) & 0xFF);
    }
}

fn long decimal_expansion(long* values, usz length, char* output, usz capacity) @export("decimal_expansion") {
    if (values == null || length != 3) return -1;
    long numerator = values[0];
    long denominator = values[1];
    long base = values[2];
    if (numerator < 0 || denominator < 1 || denominator > 256 ||
        numerator > denominator || base < 2 || base > 10) return -1;

    char[255] digits;
    long[256] first_seen;
    for (usz index = 0; index < 256; index++) first_seen[index] = -1;
    usz digit_count = 0;
    long cycle_start = -1;
    long remainder = numerator;
    while (remainder != 0 && numerator != denominator) {
        usz remainder_index = (usz)remainder;
        if (first_seen[remainder_index] >= 0) {
            cycle_start = first_seen[remainder_index];
            break;
        }
        first_seen[remainder_index] = (long)digit_count;
        long scaled = remainder * base;
        digits[digit_count++] = (char)(scaled / denominator);
        remainder = scaled % denominator;
    }

    usz required = 24 + digit_count;
    if (output == null || capacity < required) return -2;
    write_i64_le(output, 0, numerator == denominator ? 1 : 0);
    write_i64_le(output, 8, (long)digit_count);
    write_i64_le(output, 16, cycle_start);
    for (usz index = 0; index < digit_count; index++) output[24 + index] = digits[index];
    return (long)required;
}
