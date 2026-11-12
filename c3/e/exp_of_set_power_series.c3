module exp_of_set_power_series;

const long MODULUS = 998244353;
const usz MAX_N = 5;
const usz MAX_SIZE = 32;
const usz MAX_INPUT = 33;

fn usz subset_size(usz mask) {
    usz count = 0;
    while (mask > 0) { count += mask & 1; mask >>= 1; }
    return count;
}

fn void store_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (char)(bits & 255ul);
        bits >>= 8;
    }
}

fn long exp_of_set_power_series(long* input, usz length,
                                char* output, usz capacity)
    @export("exp_of_set_power_series") {
    if (input == null || length < 2 || length > MAX_INPUT) return -1;
    if (input[0] < 0 || input[0] > (long)MAX_N) return -1;
    usz n = (usz)input[0];
    usz size = (usz)1 << n;
    if (length != 1 + size || input[1] != 0) return -1;
    for (usz mask = 0; mask < size; mask++)
        if (input[1 + mask] < 0 || input[1 + mask] >= MODULUS) return -1;

    usz bytes = 8 * size;
    if (output == null || capacity < bytes) return -2;

    long[MAX_N + 1] inverse = zeroed;
    long[MAX_SIZE] result = zeroed;
    if (n > 0) inverse[1] = 1;
    for (usz k = 2; k <= n; k++)
        inverse[k] = MODULUS - (MODULUS / (long)k) * inverse[(usz)(MODULUS % (long)k)] % MODULUS;
    result[0] = 1;
    for (usz mask = 1; mask < size; mask++) {
        long total = 0;
        for (usz subset = mask; subset > 0; subset = (subset - 1) & mask) {
            long term = (long)subset_size(subset) * input[1 + subset] % MODULUS;
            term = term * result[mask ^ subset] % MODULUS;
            total = (total + term) % MODULUS;
        }
        result[mask] = total * inverse[subset_size(mask)] % MODULUS;
    }
    for (usz mask = 0; mask < size; mask++) store_le(output, 8 * mask, result[mask]);
    return (long)bytes;
}
