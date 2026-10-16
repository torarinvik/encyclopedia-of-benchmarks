module count_nucleotide;

const long MAX_SEQUENCE_LENGTH = 1000;

fn usz decimal_length(long value) {
    usz length = 1;
    while (value >= 10) { value /= 10; length++; }
    return length;
}

fn usz write_decimal(long value, char* output, usz offset) {
    long divisor = 1;
    while (value / divisor >= 10) divisor *= 10;
    while (divisor > 0) {
        output[offset] = (char)('0' + value / divisor);
        offset++;
        value %= divisor;
        divisor /= 10;
    }
    return offset;
}

fn long count_nucleotide(long* values, usz length, char* output, usz capacity) @export("count_nucleotide") {
    if (values == null || length < 1 || length > 1001) return -1;
    long count_value = values[0];
    if (count_value < 0 || count_value > MAX_SEQUENCE_LENGTH || length != (usz)count_value + 1) return -1;
    long count_a = 0, count_c = 0, count_g = 0, count_t = 0;
    for (usz i = 0; i < (usz)count_value; i++) {
        long codepoint = values[1 + i];
        if (codepoint < 0 || codepoint > 127) return -1;
        if (codepoint == 65) count_a++;
        else if (codepoint == 67) count_c++;
        else if (codepoint == 71) count_g++;
        else if (codepoint == 84) count_t++;
    }
    usz output_length = decimal_length(count_a) + decimal_length(count_c) + decimal_length(count_g) + decimal_length(count_t) + 3;
    if (output == null || capacity < output_length) return -2;
    usz offset = write_decimal(count_a, output, 0); output[offset++] = ' ';
    offset = write_decimal(count_c, output, offset); output[offset++] = ' ';
    offset = write_decimal(count_g, output, offset); output[offset++] = ' ';
    offset = write_decimal(count_t, output, offset);
    return (long)offset;
}
