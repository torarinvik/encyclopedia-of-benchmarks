module polynomial_composite_set_power_series;

const long MODULUS = 998244353;
const usz MAX_COEFFICIENTS = 8;
const usz MAX_N = 4;
const usz MAX_SIZE = 16;
const usz MAX_INPUT = 27;

fn void store_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (char)(bits & 255ul);
        bits >>= 8;
    }
}

fn long polynomial_composite_set_power_series(long* input, usz length,
    char* output, usz capacity) @export("polynomial_composite_set_power_series") {
    if (input == null || length < 2 || length > MAX_INPUT) return -1;
    if (input[0] < 0 || input[0] > (long)MAX_COEFFICIENTS ||
        input[1] < 0 || input[1] > (long)MAX_N) return -1;
    usz count = (usz)input[0];
    usz n = (usz)input[1];
    usz size = (usz)1 << n;
    if (length != 2 + count + size) return -1;
    for (usz i = 0; i < count + size; i++)
        if (input[2 + i] < 0 || input[2 + i] >= MODULUS) return -1;

    usz bytes = 8 * size;
    if (output == null || capacity < bytes) return -2;

    long[MAX_SIZE] series = zeroed;
    long[MAX_SIZE] result = zeroed;
    long[MAX_SIZE] temporary = zeroed;
    for (usz mask = 0; mask < size; mask++)
        series[mask] = input[2 + count + mask];

    for (usz degree = count; degree > 0; degree--) {
        for (usz mask = 0; mask < size; mask++) {
            long total = 0;
            usz subset = mask;
            while (true) {
                total = (total + result[subset] * series[mask ^ subset]) % MODULUS;
                if (subset == 0) break;
                subset = (subset - 1) & mask;
            }
            temporary[mask] = total;
        }
        temporary[0] = (temporary[0] + input[1 + degree]) % MODULUS;
        for (usz mask = 0; mask < size; mask++)
            result[mask] = temporary[mask];
    }
    for (usz mask = 0; mask < size; mask++)
        store_le(output, 8 * mask, result[mask]);
    return (long)bytes;
}
