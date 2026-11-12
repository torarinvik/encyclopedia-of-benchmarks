module prefix_sum_of_binomial_coefficient;

const long MODULUS = 998244353;
const usz MAX_T = 16;
const usz MAX_N = 128;
const usz MAX_INPUT_LENGTH = 34;

fn long prefix_sum_of_binomial_coefficient(long* input, usz length,
        char* output, usz capacity) @export("prefix_sum_of_binomial_coefficient") {
    if (input == null || length < 3 || length > MAX_INPUT_LENGTH) return -1;
    long count_value = input[0];
    if (count_value < 1 || count_value > 16) return -1;
    usz count = (usz)count_value;
    if (length != 1 + 2 * count) return -1;
    long ns[16], ks[16];
    for (usz query = 0; query < count; query++) {
        ns[query] = input[1 + 2 * query];
        ks[query] = input[2 + 2 * query];
        if (ns[query] < 0 || ns[query] > 128 || ks[query] < 0 || ks[query] > ns[query]) return -1;
    }
    usz output_length = 4 * count;
    if (output == null || capacity < output_length) return -2;

    long inverse[129];
    for (usz i = 0; i < 129; i++) inverse[i] = 0;
    inverse[1] = 1;
    for (usz value = 2; value <= 128; value++)
        inverse[value] = MODULUS - (MODULUS / (long)value) * inverse[(usz)(MODULUS % (long)value)] % MODULUS;
    for (usz query = 0; query < count; query++) {
        long coefficient = 1, prefix = 1;
        for (long index = 0; index < ks[query]; index++) {
            coefficient = coefficient * (ns[query] - index) % MODULUS;
            coefficient = coefficient * inverse[(usz)(index + 1)] % MODULUS;
            prefix = (prefix + coefficient) % MODULUS;
        }
        usz offset = 4 * query;
        output[offset] = (char)(prefix % 256);
        output[offset + 1] = (char)((prefix / 256) % 256);
        output[offset + 2] = (char)((prefix / 65536) % 256);
        output[offset + 3] = (char)(prefix / 16777216);
    }
    return (long)output_length;
}
