module binary_divisibility_by_three_dfa;

const usz MAX_BITS = 4096;
const usz MAX_INPUT_LENGTH = MAX_BITS + 2;

fn long binary_divisibility_by_three_dfa(long *input, usz length,
        char *output, usz output_capacity) @export("binary_divisibility_by_three_dfa") {
    if (input == null || length == 0 || length > MAX_INPUT_LENGTH) return -1;
    long bit_count = input[0];
    if (bit_count < 1 || bit_count > 4096 || (usz)bit_count + 1 != length) return -1;
    long remainder = 0;
    for (usz index = 1; index < length; index++) {
        if (input[index] != 0 && input[index] != 1) return -1;
        remainder = (2 * remainder + input[index]) % 3;
    }
    if (output == null || output_capacity < 1) return -2;

    output[0] = (char)(remainder == 0 ? 1 : 0);
    return 1;
}
