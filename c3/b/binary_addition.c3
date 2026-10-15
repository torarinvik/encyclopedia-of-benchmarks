module binary_addition;

// Add two most-significant-first binary digit arrays packed after their lengths.
fn long binary_addition(long* values, usz length, char* output, usz output_capacity) @export("binary_addition") {
    if (values == null || length < 2 || length > 4096) return -1;
    long length_a_value = values[0];
    long length_b_value = values[1];
    if (length_a_value < 0 || length_a_value > 2047 || length_b_value < 0 || length_b_value > 2047) return -1;
    usz length_a = (usz)length_a_value;
    usz length_b = (usz)length_b_value;
    if (length != 2 + length_a + length_b) return -1;
    for (usz index = 0; index < length_a; index++) {
        long digit = values[2 + index];
        if (digit != 0 && digit != 1) return -1;
    }
    for (usz index = 0; index < length_b; index++) {
        long digit = values[2 + length_a + index];
        if (digit != 0 && digit != 1) return -1;
    }

    usz width = length_a > length_b ? length_a : length_b;
    long carry = 0;
    for (usz offset = 0; offset < width; offset++) {
        long digit_a = offset < length_a ? values[2 + length_a - 1 - offset] : 0;
        long digit_b = offset < length_b ? values[2 + length_a + length_b - 1 - offset] : 0;
        long sum = digit_a + digit_b + carry;
        carry = sum >> 1;
    }
    usz output_length = width + (usz)carry;
    if (output_capacity < output_length || (output_length != 0 && output == null)) return -2;

    carry = 0;
    for (usz offset = 0; offset < width; offset++) {
        long digit_a = offset < length_a ? values[2 + length_a - 1 - offset] : 0;
        long digit_b = offset < length_b ? values[2 + length_a + length_b - 1 - offset] : 0;
        long sum = digit_a + digit_b + carry;
        output[width - 1 - offset] = (char)('0' + (sum & 1));
        carry = sum >> 1;
    }
    if (carry != 0) output[0] = '1';
    return (long)output_length;
}
