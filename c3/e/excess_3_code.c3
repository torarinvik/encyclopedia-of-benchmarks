module excess_3_code;

fn long excess_3_code(long value, char* output, usz output_capacity) @export("excess_3_code") {
    char[19] digits;
    usz count = 0;
    ulong number = value < 0 ? 0 : (ulong)value;
    do {
        digits[count] = (char)(number % 10);
        count++;
        number /= 10;
    } while (number != 0);
    usz output_length = 2 + 4 * count;
    if (output == null || output_capacity < output_length) return -2;
    output[0] = '0';
    output[1] = 'b';
    usz position = 2;
    while (count > 0) {
        count--;
        int nibble = digits[count] + 3;
        for (int bit = 8; bit != 0; bit >>= 1) {
            output[position] = (nibble & bit) != 0 ? '1' : '0';
            position++;
        }
    }
    return (long)output_length;
}
