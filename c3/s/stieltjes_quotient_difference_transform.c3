module stieltjes_quotient_difference_transform;

const long MODULUS = 998244353;
const usz MAX_WORDS = 11;
const usz TABLE_COLUMNS = 9;

fn long stieltjes_mod(long value) {
    value %= MODULUS;
    return value < 0 ? value + MODULUS : value;
}

fn long stieltjes_mul(long left, long right) { return (left * right) % MODULUS; }

fn long stieltjes_power(long base, long exponent) {
    long result = 1;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = stieltjes_mul(result, base);
        base = stieltjes_mul(base, base);
        exponent >>= 1;
    }
    return result;
}

fn void stieltjes_store_i64(uchar* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) output[offset + byte] = (uchar)(bits >> (8 * byte));
}

fn long stieltjes_quotient_difference_transform(long* input, usz input_length,
                                                uchar* output, usz output_capacity)
        @export("stieltjes_quotient_difference_transform") {
    if (input == null || input_length < 3 || input_length > MAX_WORDS) return -1;
    long n0 = input[0];
    if (n0 < 2 || n0 > 9 || input_length != (usz)n0 + 1) return -1;
    usz n = (usz)n0;
    for (usz i = 0; i < n; i++)
        if (input[i + 1] <= 0 || input[i + 1] >= MODULUS) return -1;

    long[5][9] q = zeroed;
    long[5][9] e = zeroed;
    for (usz k = 0; k + 1 < n; k++)
        q[1][k] = stieltjes_mul(input[k + 2], stieltjes_power(input[k + 1], MODULUS - 2));
    for (int j = 1; j <= 4; j++) {
        int last_e = (int)n - 2 * j - 1;
        if (last_e < 0) break;
        for (int k = 0; k <= last_e; k++)
            e[j][k] = stieltjes_mod(e[j - 1][k + 1] + q[j][k + 1] - q[j][k]);
        int last_q = (int)n - 2 * j - 2;
        if (last_q >= 0) {
            for (int k = 0; k <= last_q; k++) {
                long pivot = e[j][k];
                if (pivot == 0) return -1;
                long product = stieltjes_mul(q[j][k + 1], e[j][k + 1]);
                q[j + 1][k] = stieltjes_mul(product, stieltjes_power(pivot, MODULUS - 2));
            }
        }
    }

    usz required = 8 * (n + 1);
    if (output == null || output_capacity < required) return -2;
    stieltjes_store_i64(output, 0, n0);
    for (usz index = 1; index < n; index++) {
        long value = (index & 1) != 0 ? q[(index + 1) / 2][0] : e[index / 2][0];
        stieltjes_store_i64(output, 8 * index, value);
    }
    return (long)required;
}
