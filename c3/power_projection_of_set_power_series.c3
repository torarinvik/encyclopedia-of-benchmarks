module power_projection_of_set_power_series;

const long MODULUS = 998244353;
const usz MAX_N = 4;
const usz MAX_M = 8;
const usz MAX_SIZE = 16;
const usz MAX_INPUT = 35;

fn void store_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (char)(bits & 255ul);
        bits >>= 8;
    }
}

fn long power_projection_of_set_power_series(long* input, usz length,
                                             char* output, usz capacity)
    @export("power_projection_of_set_power_series") {
    if (input == null || length < 2 || length > MAX_INPUT) return -1;
    if (input[0] < 0 || input[0] > (long)MAX_N ||
        input[1] < 0 || input[1] > (long)MAX_M) return -1;
    usz n = (usz)input[0];
    usz powers = (usz)input[1];
    usz size = (usz)1 << n;
    if (length != 2 + 2 * size) return -1;

    long[MAX_SIZE] series = zeroed;
    long[MAX_SIZE] weights = zeroed;
    for (usz mask = 0; mask < size; mask++) {
        long a = input[2 + mask];
        long w = input[2 + size + mask];
        if (a < 0 || a >= MODULUS || w < 0 || w >= MODULUS) return -1;
        series[mask] = a;
        weights[mask] = w;
    }

    usz bytes = 8 * powers;
    if (output == null || capacity < bytes) return -2;

    long[MAX_SIZE] current = zeroed;
    long[MAX_SIZE] next = zeroed;
    current[0] = 1;
    for (usz power = 0; power < powers; power++) {
        long projection = 0;
        for (usz mask = 0; mask < size; mask++)
            projection = (projection + weights[mask] * current[mask]) % MODULUS;
        store_le(output, 8 * power, projection);
        if (power + 1 == powers) break;
        for (usz mask = 0; mask < size; mask++) {
            long total = 0;
            usz subset = mask;
            while (true) {
                total = (total + current[subset] * series[mask ^ subset]) % MODULUS;
                if (subset == 0) break;
                subset = (subset - 1) & mask;
            }
            next[mask] = total;
        }
        for (usz mask = 0; mask < size; mask++) current[mask] = next[mask];
    }
    return (long)bytes;
}
