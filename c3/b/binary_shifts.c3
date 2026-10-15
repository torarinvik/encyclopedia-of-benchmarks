module binary_shifts;

fn usz unsigned_bits(ulong value, char* bits) {
    usz length = 0;
    do { bits[length] = (char)('0' + (value & 1)); length++; value >>= 1; } while (value != 0);
    for (usz left = 0, right = length - 1; left < right; left++, right--) {
        char temporary = bits[left]; bits[left] = bits[right]; bits[right] = temporary;
    }
    return length;
}

fn long binary_shifts(long* values, usz length, char* output, usz output_capacity)
    @export("binary_shifts") {
    if (values == null || length != 3) return -1;
    long operation = values[0], number = values[1], shift = values[2];
    if (operation < 0 || operation > 2 || number < -2147483647 || number > 2147483647 ||
        shift < 0 || shift > 31 || (operation < 2 && number < 0)) return -1;

    char bits[80], result[82];
    usz bits_length = 0, result_length = 0;
    if (operation == 0 || operation == 1) {
        bits_length = unsigned_bits((ulong)number, bits);
        result[0] = '0'; result[1] = 'b'; result_length = 2;
        if (operation == 0) {
            for (usz i = 0; i < bits_length; i++) result[result_length++] = bits[i];
            for (long i = 0; i < shift; i++) result[result_length++] = '0';
        } else if ((usz)shift >= bits_length) result[result_length++] = '0';
        else for (usz i = 0; i < bits_length - (usz)shift; i++) result[result_length++] = bits[i];
    } else {
        if (number >= 0) {
            bits[0] = '0'; bits_length = 1 + unsigned_bits((ulong)number, bits + 1);
        } else {
            ulong magnitude = (ulong)(-number);
            usz magnitude_length = unsigned_bits(magnitude, bits);
            ulong complement = (1ul << magnitude_length) - magnitude;
            char complement_bits[40];
            usz complement_length = unsigned_bits(complement, complement_bits);
            bits[0] = '1'; usz position = 1;
            for (usz i = complement_length; i < magnitude_length; i++) bits[position++] = '0';
            for (usz i = 0; i < complement_length; i++) bits[position++] = complement_bits[i];
            bits_length = position;
        }
        result[0] = '0'; result[1] = 'b'; result_length = 2;
        char sign = bits[0];
        if ((usz)shift >= bits_length) for (usz i = 0; i < bits_length; i++) result[result_length++] = sign;
        else {
            for (long i = 0; i < shift; i++) result[result_length++] = sign;
            for (usz i = 0; i < bits_length - (usz)shift; i++) result[result_length++] = bits[i];
        }
    }
    if (output == null || output_capacity < result_length) return -2;
    for (usz i = 0; i < result_length; i++) output[i] = result[i];
    return (long)result_length;
}
