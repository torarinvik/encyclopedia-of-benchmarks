module int_to_string;

const long MAX_VALUE = 65535;
const usz MAX_DIGITS = 16;

fn long int_to_string(long packed, char* output, usz output_capacity) @export("int_to_string") {
    if (packed < 0) return -1;
    long value = packed / 15;
    long base = packed % 15 + 2;
    if (value > MAX_VALUE) return -1;
    char[MAX_DIGITS] digits;
    usz count = 0;
    long remaining = value;
    do {
        long digit = remaining % base;
        if (digit < 10) {
            digits[count++] = (char)('0' + digit);
        } else {
            digits[count++] = (char)('a' + digit - 10);
        }
        remaining /= base;
    } while (remaining != 0);
    usz required = count + 1;
    if (output == null || output_capacity < required) return -2;
    for (usz index = 0; index < count; index++) output[index] = digits[count - index - 1];
    output[count] = 0;
    return (long)required;
}
