module balanced_ternary_conversion;

const MAX_OUTPUT_BYTES = 41;

fn long balanced_ternary_conversion(long* input, usz length, char* output, usz capacity)
        @export("balanced_ternary_conversion") {
    if (input == null || length != 1) return -1;
    char[MAX_OUTPUT_BYTES] reversed = {};
    usz digit_count = 0;
    long value = input[0];
    if (value == 0) reversed[digit_count++] = '0';
    while (value != 0) {
        long quotient = value / 3;
        long remainder = value % 3;
        char digit;
        if (remainder == 2) { digit = 'Z'; quotient++; }
        else if (remainder == -2) { digit = '1'; quotient--; }
        else if (remainder == -1) digit = 'Z';
        else if (remainder == 0) digit = '0';
        else digit = '1';
        reversed[digit_count++] = digit;
        value = quotient;
    }
    if (output == null || capacity < digit_count) return -2;
    for (usz index = 0; index < digit_count; index++) output[index] = reversed[digit_count - index - 1];
    return (long)digit_count;
}
