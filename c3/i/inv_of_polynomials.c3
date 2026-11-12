module inv_of_polynomials;

const long MODULUS = 998244353;
const usz MAX_LENGTH = 6;
const usz MAX_INPUT = 14;
const usz CAPACITY = 16;

fn long power_mod(long base, long exponent) {
    long result = 1;
    while (exponent > 0) {
        if (exponent % 2 != 0) result = result * base % MODULUS;
        base = base * base % MODULUS;
        exponent /= 2;
    }
    return result;
}

fn usz trim_poly(long* polynomial, usz length) {
    while (length > 0 && polynomial[length - 1] == 0) length -= 1;
    return length;
}

fn void copy_poly(long* destination, long* source, usz length) {
    for (usz i = 0; i < CAPACITY; i++) destination[i] = i < length ? source[i] : 0;
}

fn void divide_poly(long* dividend, usz dividend_length, long* divisor, usz divisor_length,
                    long* quotient, usz* quotient_length, long* remainder, usz* remainder_length) {
    for (usz i = 0; i < CAPACITY; i++) {
        quotient[i] = 0;
        remainder[i] = i < dividend_length ? dividend[i] : 0;
    }
    *remainder_length = trim_poly(remainder, dividend_length);
    if (*remainder_length >= divisor_length) {
        long inverse_lead = power_mod(divisor[divisor_length - 1], MODULUS - 2);
        while (*remainder_length >= divisor_length) {
            usz shift = *remainder_length - divisor_length;
            long factor = remainder[*remainder_length - 1] * inverse_lead % MODULUS;
            quotient[shift] = factor;
            for (usz j = 0; j < divisor_length; j++) {
                long value = (remainder[shift + j] - factor * divisor[j]) % MODULUS;
                if (value < 0) value += MODULUS;
                remainder[shift + j] = value;
            }
            *remainder_length = trim_poly(remainder, *remainder_length);
        }
    }
    usz q_bound = dividend_length >= divisor_length ? dividend_length - divisor_length + 1 : 0;
    *quotient_length = trim_poly(quotient, q_bound);
}

fn void multiply_poly(long* left, usz left_length, long* right, usz right_length,
                      long* product, usz* product_length) {
    for (usz i = 0; i < CAPACITY; i++) product[i] = 0;
    if (left_length == 0 || right_length == 0) {
        *product_length = 0;
        return;
    }
    for (usz i = 0; i < left_length; i++) {
        for (usz j = 0; j < right_length && i + j < CAPACITY; j++) {
            product[i + j] = (product[i + j] + left[i] * right[j]) % MODULUS;
        }
    }
    usz bound = left_length + right_length - 1 < CAPACITY ? left_length + right_length - 1 : CAPACITY;
    *product_length = trim_poly(product, bound);
}

fn void subtract_poly(long* left, usz left_length, long* right, usz right_length,
                      long* difference, usz* difference_length) {
    usz bound = left_length > right_length ? left_length : right_length;
    for (usz i = 0; i < CAPACITY; i++) difference[i] = 0;
    for (usz i = 0; i < bound; i++) {
        long a = i < left_length ? left[i] : 0;
        long b = i < right_length ? right[i] : 0;
        difference[i] = (a - b + MODULUS) % MODULUS;
    }
    *difference_length = trim_poly(difference, bound);
}

fn void store_le(uint8* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (uint8)(bits & 255ul);
        bits >>= 8;
    }
}

fn long inv_of_polynomials(long* input, usz length, uint8* output, usz capacity)
    @export("inv_of_polynomials") {
    if (input == null || length < 4 || length > MAX_INPUT) return -1;
    long n_value = input[0];
    long m_value = input[1];
    if (n_value < 1 || n_value > (long)MAX_LENGTH || m_value < 1 || m_value > (long)MAX_LENGTH) return -1;
    usz n = (usz)n_value;
    usz m = (usz)m_value;
    if (length != 2 + n + m) return -1;
    long[CAPACITY] f = {0};
    long[CAPACITY] g = {0};
    for (usz i = 0; i < n; i++) {
        f[i] = input[2 + i];
        if (f[i] < 0 || f[i] >= MODULUS) return -1;
    }
    for (usz i = 0; i < m; i++) {
        g[i] = input[2 + n + i];
        if (g[i] < 0 || g[i] >= MODULUS) return -1;
    }
    if (f[n - 1] == 0 || g[m - 1] == 0) return -1;

    long[CAPACITY] inverse = {0};
    usz inverse_length = 0;
    if (m > 1) {
        long[CAPACITY] r0 = {0};
        long[CAPACITY] r1 = {0};
        long[CAPACITY] s0 = {0};
        long[CAPACITY] s1 = {0};
        long[CAPACITY] ignored_q = {0};
        long[CAPACITY] initial_remainder = {0};
        usz ignored_q_length = 0;
        usz r1_length = 0;
        divide_poly(&f[0], n, &g[0], m, &ignored_q[0], &ignored_q_length, &initial_remainder[0], &r1_length);
        copy_poly(&r0[0], &g[0], m);
        copy_poly(&r1[0], &initial_remainder[0], r1_length);
        usz r0_length = m;
        usz s0_length = 0;
        usz s1_length = 1;
        s1[0] = 1;
        while (r1_length > 0) {
            long[CAPACITY] quotient = {0};
            long[CAPACITY] remainder = {0};
            long[CAPACITY] product = {0};
            long[CAPACITY] next_s = {0};
            usz quotient_length = 0;
            usz remainder_length = 0;
            usz product_length = 0;
            usz next_s_length = 0;
            divide_poly(&r0[0], r0_length, &r1[0], r1_length, &quotient[0], &quotient_length, &remainder[0], &remainder_length);
            multiply_poly(&quotient[0], quotient_length, &s1[0], s1_length, &product[0], &product_length);
            subtract_poly(&s0[0], s0_length, &product[0], product_length, &next_s[0], &next_s_length);
            copy_poly(&r0[0], &r1[0], r1_length);
            r0_length = r1_length;
            copy_poly(&r1[0], &remainder[0], remainder_length);
            r1_length = remainder_length;
            copy_poly(&s0[0], &s1[0], s1_length);
            s0_length = s1_length;
            copy_poly(&s1[0], &next_s[0], next_s_length);
            s1_length = next_s_length;
        }
        if (r0_length != 1) return -1;
        long scale = power_mod(r0[0], MODULUS - 2);
        for (usz i = 0; i < s0_length; i++) inverse[i] = s0[i] * scale % MODULUS;
        inverse_length = trim_poly(&inverse[0], s0_length);
    }

    usz bytes = 8 * inverse_length;
    if (output == null || capacity < bytes) return -2;
    for (usz i = 0; i < inverse_length; i++) store_le(output, 8 * i, inverse[i]);
    return (long)bytes;
}
