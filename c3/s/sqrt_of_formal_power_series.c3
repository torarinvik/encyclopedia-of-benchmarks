module sqrt_of_formal_power_series;

const long MODULUS = 998244353;
const usz MAX_N = 64;
const usz MAX_INPUT = 66;

fn long fps_mod_pow(long base, long exponent) {
    long result = 1;
    while (exponent > 0) {
        if (exponent % 2 != 0) result = result * base % MODULUS;
        base = base * base % MODULUS;
        exponent /= 2;
    }
    return result;
}

fn long fps_mod_sqrt(long value) {
    if (value == 0) return 0;
    if (fps_mod_pow(value, (MODULUS - 1) / 2) != 1) return -1;
    long odd_part = MODULUS - 1;
    usz twos = 0;
    while (odd_part % 2 == 0) { odd_part /= 2; twos++; }
    long non_residue = 2;
    while (fps_mod_pow(non_residue, (MODULUS - 1) / 2) != MODULUS - 1) non_residue++;
    long c = fps_mod_pow(non_residue, odd_part);
    long root = fps_mod_pow(value, (odd_part + 1) / 2);
    long remainder = fps_mod_pow(value, odd_part);
    usz order = twos;
    while (remainder != 1) {
        usz index = 1;
        long probe = remainder * remainder % MODULUS;
        while (index < order && probe != 1) { probe = probe * probe % MODULUS; index++; }
        if (index >= order || probe != 1) return -1;
        long exponent = 1;
        for (usz bit = 0; bit < order - index - 1; bit++) exponent *= 2;
        long factor = fps_mod_pow(c, exponent);
        root = root * factor % MODULUS;
        long factor_squared = factor * factor % MODULUS;
        remainder = remainder * factor_squared % MODULUS;
        c = factor_squared;
        order = index;
    }
    return root < MODULUS - root ? root : MODULUS - root;
}

fn void fps_store_le(uint8* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (uint8)(bits & 255ul);
        bits >>= 8;
    }
}

fn long sqrt_of_formal_power_series(long* input, usz length,
                                    uint8* output, usz capacity)
    @export("sqrt_of_formal_power_series") {
    if (input == null || length < 2 || length > MAX_INPUT) return -1;
    if (input[0] < 1 || input[0] > (long)MAX_N) return -1;
    usz n = (usz)input[0];
    if (length != n + 1) return -1;
    for (usz i = 0; i < n; i++) if (input[i + 1] < 0 || input[i + 1] >= MODULUS) return -1;
    usz bytes = 8 * n;
    if (output == null || capacity < bytes) return -2;

    long[MAX_N] result = {0};
    usz valuation = 0;
    while (valuation < n && input[valuation + 1] == 0) valuation++;
    if (valuation == n) {
        for (usz i = 0; i < n; i++) fps_store_le(output, 8 * i, 0);
        return (long)bytes;
    }
    if (valuation % 2 != 0) { fps_store_le(output, 0, -1); return 8; }
    usz shift = valuation / 2;
    long leading_root = fps_mod_sqrt(input[valuation + 1]);
    if (leading_root < 0) { fps_store_le(output, 0, -1); return 8; }
    long inverse_twice_root = fps_mod_pow((2 * leading_root) % MODULUS, MODULUS - 2);
    usz width = n - valuation;
    result[shift] = leading_root;
    for (usz degree = 1; degree < width; degree++) {
        long cross_terms = 0;
        for (usz i = 1; i < degree; i++)
            cross_terms = (cross_terms + result[shift + i] * result[shift + degree - i]) % MODULUS;
        long delta = (input[valuation + degree + 1] - cross_terms) % MODULUS;
        if (delta < 0) delta += MODULUS;
        result[shift + degree] = delta * inverse_twice_root % MODULUS;
    }
    for (usz i = 0; i < n; i++) fps_store_le(output, 8 * i, result[i]);
    return (long)bytes;
}
