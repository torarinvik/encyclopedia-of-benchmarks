module binary_twos_complement;

fn long twos_complement(long value, char* output, usz output_capacity) @export("twos_complement") {
    if (value > 0) return -1;
    if (value == 0) {
        if (output == null || output_capacity < 3) return -2;
        output[0] = '0'; output[1] = 'b'; output[2] = '0';
        return 3;
    }
    ulong magnitude = (ulong)(-(value + 1)) + 1;
    usz bit_length = 0;
    for (ulong remaining = magnitude; remaining != 0; remaining >>= 1) bit_length++;
    ulong suffix = magnitude;
    if (bit_length < 64) {
        ulong power = 1;
        for (usz exponent = 0; exponent < bit_length; exponent++) power *= 2;
        suffix = power - magnitude;
    }
    char[64] bits;
    usz bit_count = 0;
    for (ulong remaining = suffix; remaining != 0; remaining >>= 1) bits[bit_count++] = (char)('0' + (remaining & 1ul));
    usz required = bit_length + 3;
    if (output == null || output_capacity < required) return -2;
    usz position = 0;
    output[position++] = '0'; output[position++] = 'b'; output[position++] = '1';
    for (usz zero = bit_count; zero < bit_length; zero++) output[position++] = '0';
    while (bit_count > 0) output[position++] = bits[--bit_count];
    return (long)position;
}
