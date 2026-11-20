module cyclotomic_polynomial_coefficients;

const usz MAX_N = 32;
const usz MAX_INPUT_LENGTH = 2;

fn void store_i64_le(char *output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long cyclotomic_polynomial_coefficients(long *input, usz length,
                                            char *output, usz capacity)
    @export("cyclotomic_polynomial_coefficients") {
    if (input == null || length == 0 || length > MAX_INPUT_LENGTH) return -1;
    long n_value = input[0];
    if (n_value < 1 || n_value > (long)MAX_N || length != 1) return -1;
    usz n = (usz)n_value;

    long polynomials[33][33] = {};
    usz degrees[33] = {};
    polynomials[1][0] = -1;
    polynomials[1][1] = 1;
    degrees[1] = 1;
    for (usz k = 2; k <= n; k++) {
        long divisor[33] = {};
        divisor[0] = 1;
        usz divisor_degree = 0;
        for (usz d = 1; d < k; d++) {
            if (k % d != 0) continue;
            long product[33] = {};
            for (usz i = 0; i <= divisor_degree; i++)
                for (usz j = 0; j <= degrees[d]; j++)
                    product[i + j] += divisor[i] * polynomials[d][j];
            divisor_degree += degrees[d];
            for (usz i = 0; i <= divisor_degree; i++) divisor[i] = product[i];
        }
        long remainder[33] = {};
        remainder[0] = -1;
        remainder[k] = 1;
        usz quotient_degree = k - divisor_degree;
        degrees[k] = quotient_degree;
        for (long q = (long)quotient_degree; q >= 0; q--) {
            long leading = remainder[divisor_degree + (usz)q];
            polynomials[k][(usz)q] = leading;
            for (usz j = 0; j <= divisor_degree; j++)
                remainder[(usz)q + j] -= leading * divisor[j];
        }
    }

    usz coefficient_count = degrees[n] + 1;
    usz required = 8 * coefficient_count;
    if (output == null || capacity < required) return -2;
    for (usz index = 0; index < coefficient_count; index++)
        store_i64_le(output, 8 * index, polynomials[n][index]);
    return (long)required;
}
