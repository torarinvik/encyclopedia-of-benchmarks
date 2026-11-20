module pade_approximant_series_coefficients;

const long MODULUS = 998244353;
const usz MAX_INPUT_LENGTH = 12;

fn long mod_pow(long base, long exponent) {
    long result = 1;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = result * base % MODULUS;
        base = base * base % MODULUS;
        exponent >>= 1;
    }
    return result;
}

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long pade_approximant_series_coefficients(long* input, usz length,
    char* output, usz capacity) @export("pade_approximant_series_coefficients") {
    if (input == null || length < 5 || length > MAX_INPUT_LENGTH) return -1;
    long p_value = input[0];
    long q_value = input[1];
    if (q_value < 1 || p_value < q_value || p_value > 4 || q_value > 4 ||
        length != (usz)(p_value + q_value + 3)) return -1;
    usz p = (usz)p_value;
    usz q = (usz)q_value;
    uint[9] coefficients = {0};
    for (usz i = 0; i <= p + q; i++) {
        if (input[i + 2] < 0 || input[i + 2] >= MODULUS) return -1;
        coefficients[i] = (uint)input[i + 2];
    }
    usz required = 8 * (p + q + 4);
    if (output == null || capacity < required) return -2;

    uint[20] matrix = {0};
    for (usz row = 0; row < q; row++) {
        usz m = p + 1 + row;
        for (usz col = 0; col < q; col++) matrix[row * 5 + col] = coefficients[m - col - 1];
        matrix[row * 5 + q] = (uint)((MODULUS - (long)coefficients[m]) % MODULUS);
    }
    for (usz col = 0; col < q; col++) {
        usz pivot = col;
        while (pivot < q && matrix[pivot * 5 + col] == 0) pivot++;
        if (pivot == q) return -3;
        if (pivot != col) {
            for (usz j = 0; j <= q; j++) {
                uint temporary = matrix[col * 5 + j];
                matrix[col * 5 + j] = matrix[pivot * 5 + j];
                matrix[pivot * 5 + j] = temporary;
            }
        }
        long inverse = mod_pow((long)matrix[col * 5 + col], MODULUS - 2);
        for (usz j = col; j <= q; j++)
            matrix[col * 5 + j] = (uint)((long)matrix[col * 5 + j] * inverse % MODULUS);
        for (usz row = 0; row < q; row++) {
            if (row == col) continue;
            long factor = (long)matrix[row * 5 + col];
            for (usz j = col; j <= q; j++) {
                long product = factor * (long)matrix[col * 5 + j] % MODULUS;
                long difference = (long)matrix[row * 5 + j] - product;
                if (difference < 0) difference += MODULUS;
                matrix[row * 5 + j] = (uint)difference;
            }
        }
    }
    store_i64_le(output, 0, p_value);
    store_i64_le(output, 8, q_value);
    usz offset = 16;
    for (usz m = 0; m <= p; m++) {
        ulong value = (ulong)coefficients[m];
        usz last = m < q ? m : q;
        for (usz j = 1; j <= last; j++)
            value = (value + (ulong)coefficients[m-j] * (ulong)matrix[(j-1)*5+q]) % (ulong)MODULUS;
        store_i64_le(output, offset, (long)value);
        offset += 8;
    }
    store_i64_le(output, offset, 1);
    offset += 8;
    for (usz j = 0; j < q; j++) {
        store_i64_le(output, offset, (long)matrix[j*5+q]);
        offset += 8;
    }
    return (long)required;
}
