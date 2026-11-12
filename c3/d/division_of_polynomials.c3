module division_of_polynomials;

const long MODULUS = 998244353;
const usz MAX_N = 64;
const usz MAX_INPUT = 131;
const usz MAX_OUTPUT_BYTES = 536;

fn long power_mod(long base, long exponent) {
    long result = 1;
    while (exponent > 0) {
        if (exponent & 1) result = result * base % MODULUS;
        base = base * base % MODULUS;
        exponent >>= 1;
    }
    return result;
}

fn usz trim_poly(long* polynomial, usz length) {
    while (length > 0 && polynomial[length - 1] == 0) length -= 1;
    return length;
}

fn void store_le(uint8* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (uint8)(bits & 255ul);
        bits >>= 8;
    }
}

fn long division_of_polynomials(long* input, usz length, uint8* output, usz capacity)
    @export("division_of_polynomials") {
    if (input == null || length < 4 || length > MAX_INPUT) return -1;
    if (input[0] < 1 || input[0] > (long)MAX_N || input[1] < 1 || input[1] > (long)MAX_N) return -1;
    usz n = (usz)input[0];
    usz m = (usz)input[1];
    if (length != 2 + n + m) return -1;

    long[MAX_N] work = {0};
    long[MAX_N] quotient = {0};
    for (usz i = 0; i < n; i++) {
        work[i] = input[2 + i];
        if (work[i] < 0 || work[i] >= MODULUS) return -1;
    }
    for (usz i = 0; i < m; i++)
        if (input[2 + n + i] < 0 || input[2 + n + i] >= MODULUS) return -1;
    if (work[n - 1] == 0 || input[2 + n + m - 1] == 0) return -1;

    usz quotient_bound = 0;
    if (n >= m) {
        quotient_bound = n - m + 1;
        long inverse_leading = power_mod(input[2 + n + m - 1], MODULUS - 2);
        for (usz shift_plus_one = quotient_bound; shift_plus_one > 0; shift_plus_one--) {
            usz shift = shift_plus_one - 1;
            long factor = work[shift + m - 1] * inverse_leading % MODULUS;
            quotient[shift] = factor;
            for (usz j = 0; j < m; j++) {
                long value = (work[shift + j] - factor * input[2 + n + j]) % MODULUS;
                if (value < 0) value += MODULUS;
                work[shift + j] = value;
            }
        }
    }

    usz quotient_length = trim_poly(&quotient[0], quotient_bound);
    usz remainder_bound = n < m ? n : m;
    usz remainder_length = trim_poly(&work[0], remainder_bound);
    usz bytes = 8 * (2 + quotient_length + remainder_length);
    if (bytes > MAX_OUTPUT_BYTES) return -1;
    if (output == null || capacity < bytes) return -2;

    store_le(output, 0, (long)quotient_length);
    store_le(output, 8, (long)remainder_length);
    usz offset = 16;
    for (usz i = 0; i < quotient_length; i++, offset += 8) store_le(output, offset, quotient[i]);
    for (usz i = 0; i < remainder_length; i++, offset += 8) store_le(output, offset, work[i]);
    return (long)bytes;
}
