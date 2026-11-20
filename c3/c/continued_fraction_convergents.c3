module continued_fraction_convergents;

const usz MAX_INPUT_LENGTH = 18;

fn void store_i64_le(char *output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long continued_fraction_convergents(long *input, usz length, char *output, usz capacity)
    @export("continued_fraction_convergents") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    long count_value = input[0];
    if (count_value < 1 || count_value > 16 || input[1] < -1000 || input[1] > 1000) return -1;
    usz count = (usz)count_value;
    if (length != count + 1) return -1;
    for (usz i = 2; i < length; i++) if (input[i] < 1 || input[i] > 8) return -1;
    usz required = 16 * count;
    if (output == null || capacity < required) return -2;

    long p_two_back = 0, p_one_back = 1;
    long q_two_back = 1, q_one_back = 0;
    for (usz i = 0; i < count; i++) {
        long p = input[i + 1] * p_one_back + p_two_back;
        long q = input[i + 1] * q_one_back + q_two_back;
        store_i64_le(output, 16 * i, p);
        store_i64_le(output, 16 * i + 8, q);
        p_two_back = p_one_back; p_one_back = p;
        q_two_back = q_one_back; q_one_back = q;
    }
    return (long)required;
}
