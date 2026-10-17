module print_reverse;

const usz MAX_VALUES = 256;
const usz MAX_PARSEABLE_INPUT_LENGTH = MAX_VALUES + 2;
const usz MAX_OUTPUT_BYTES = 3836;
const long I32_MIN_VALUE = -2147483648;
const long I32_MAX_VALUE = 2147483647;

fn void append_decimal(char* buffer, usz* position, long value) {
    char[10] digits;
    usz count = 0;
    ulong magnitude;
    if (value < 0) {
        buffer[*position] = '-';
        (*position)++;
        magnitude = (ulong)(-value);
    } else {
        magnitude = (ulong)value;
    }
    do {
        digits[count] = (char)('0' + magnitude % 10);
        count++;
        magnitude /= 10;
    } while (magnitude != 0);
    while (count > 0) {
        count--;
        buffer[*position] = digits[count];
        (*position)++;
    }
}

fn long print_reverse(long* values, usz length, char* output, usz output_capacity)
        @export("print_reverse") {
    if (length > MAX_PARSEABLE_INPUT_LENGTH || length > MAX_VALUES) return -1;
    if (length > 0 && values == null) return -1;
    for (usz index = 0; index < length; index++)
        if (values[index] < I32_MIN_VALUE || values[index] > I32_MAX_VALUE) return -1;

    char[MAX_OUTPUT_BYTES] encoded;
    usz written = 0;
    usz remaining = length;
    while (remaining > 0) {
        remaining--;
        if (written != 0) {
            encoded[written] = ' ';
            encoded[written + 1] = '<';
            encoded[written + 2] = '-';
            encoded[written + 3] = ' ';
            written += 4;
        }
        append_decimal(&encoded[0], &written, values[remaining]);
    }

    if (output == null || output_capacity < written) return -2;
    for (usz index = 0; index < written; index++) output[index] = encoded[index];
    return (long)written;
}
