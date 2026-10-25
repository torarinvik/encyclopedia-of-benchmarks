module tsvc_s312_array_product;

const usz MAX_N = 48;
const usz MAX_INPUT_LENGTH = 1 + MAX_N;
const long MAX_VALUE = 2;

fn long tsvc_s312_array_product(long* input, usz length)
        @export("tsvc_s312_array_product") {
    if (input == null || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    long n_raw = input[0];
    if (n_raw < 0 || n_raw > (long)MAX_N) return -1;
    usz n = (usz)n_raw;
    if (length != 1 + n) return -1;

    long product = 1;
    for (usz i = 0; i < n; i += 1) {
        long value = input[i + 1];
        if (value < 0 || value > MAX_VALUE) return -1;
        product *= value;
    }
    return product;
}
