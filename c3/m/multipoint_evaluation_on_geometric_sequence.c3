module multipoint_evaluation_on_geometric_sequence;

const long MODULUS = 998244353;
const usz MAX_N = 8, MAX_M = 8, NTT_SIZE = 32, MAX_INPUT = 12;

fn long mod_pow(long base, long exponent) {
    long result = 1;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = result * base % MODULUS;
        base = base * base % MODULUS;
        exponent >>= 1;
    }
    return result;
}

fn void ntt(long* values, bool inverse) {
    usz j = 0;
    for (usz i = 1; i < NTT_SIZE; i++) {
        usz bit = NTT_SIZE / 2;
        while ((j & bit) != 0) { j ^= bit; bit >>= 1; }
        j ^= bit;
        if (i < j) { long swap = values[i]; values[i] = values[j]; values[j] = swap; }
    }
    for (usz block = 2; block <= NTT_SIZE; block <<= 1) {
        long root = mod_pow(3, (MODULUS - 1) / (long)block);
        if (inverse) root = mod_pow(root, MODULUS - 2);
        usz half = block / 2;
        for (usz start = 0; start < NTT_SIZE; start += block) {
            long factor = 1;
            for (usz offset = 0; offset < half; offset++) {
                long even = values[start + offset];
                long odd = values[start + offset + half] * factor % MODULUS;
                values[start + offset] = (even + odd) % MODULUS;
                values[start + offset + half] = (even - odd + MODULUS) % MODULUS;
                factor = factor * root % MODULUS;
            }
        }
    }
    if (inverse) {
        long scale = mod_pow((long)NTT_SIZE, MODULUS - 2);
        for (usz i = 0; i < NTT_SIZE; i++) values[i] = values[i] * scale % MODULUS;
    }
}

fn long evaluate(long* coefficients, usz count, long x) {
    long value = 0;
    for (usz i = count; i > 0; i--) value = (value * x + coefficients[i - 1]) % MODULUS;
    return value;
}

fn void store_le(uint8* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) { output[offset + byte] = (uint8)(bits & 255ul); bits >>= 8; }
}

fn long multipoint_evaluation_on_geometric_sequence(long* input, usz length,
    uint8* output, usz capacity) @export("multipoint_evaluation_on_geometric_sequence") {
    if (input == null || length < 5 || length > MAX_INPUT) return -1;
    if (input[0] < 1 || input[0] > (long)MAX_N || input[1] < 1 || input[1] > (long)MAX_M) return -1;
    usz n = (usz)input[0], m = (usz)input[1];
    long start = input[2], ratio = input[3];
    if (length != n + 4 || start < 0 || start >= MODULUS || ratio < 0 || ratio >= MODULUS) return -1;
    for (usz i = 0; i < n; i++) if (input[4 + i] < 0 || input[4 + i] >= MODULUS) return -1;
    usz bytes = 8 * m;
    if (output == null || capacity < bytes) return -2;
    if (start == 0) {
        for (usz i = 0; i < m; i++) store_le(output, 8 * i, input[4]);
        return (long)bytes;
    }
    if (ratio == 0) {
        store_le(output, 0, evaluate(input + 4, n, start));
        for (usz i = 1; i < m; i++) store_le(output, 8 * i, input[4]);
        return (long)bytes;
    }

    long[NTT_SIZE] left = zeroed, right = zeroed;
    long inverse_ratio = mod_pow(ratio, MODULUS - 2);
    long start_power = 1, inverse_chirp = 1, inverse_ratio_power = 1;
    for (usz degree = 0; degree < n; degree++) {
        left[n - 1 - degree] = input[4 + degree] * start_power % MODULUS * inverse_chirp % MODULUS;
        start_power = start_power * start % MODULUS;
        inverse_chirp = inverse_chirp * inverse_ratio_power % MODULUS;
        inverse_ratio_power = inverse_ratio_power * inverse_ratio % MODULUS;
    }
    long chirp = 1, ratio_power = 1;
    for (usz index = 0; index < n + m - 1; index++) {
        right[index] = chirp;
        chirp = chirp * ratio_power % MODULUS;
        ratio_power = ratio_power * ratio % MODULUS;
    }
    ntt(&left[0], false);
    ntt(&right[0], false);
    for (usz i = 0; i < NTT_SIZE; i++) left[i] = left[i] * right[i] % MODULUS;
    ntt(&left[0], true);
    inverse_chirp = 1;
    inverse_ratio_power = 1;
    for (usz i = 0; i < m; i++) {
        store_le(output, 8 * i, left[n - 1 + i] * inverse_chirp % MODULUS);
        inverse_chirp = inverse_chirp * inverse_ratio_power % MODULUS;
        inverse_ratio_power = inverse_ratio_power * inverse_ratio % MODULUS;
    }
    return (long)bytes;
}
