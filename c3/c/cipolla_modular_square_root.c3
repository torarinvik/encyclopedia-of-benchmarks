module cipolla_modular_square_root;

const long MAX_PRIME = 1000003;

struct ExtensionValue {
    long real;
    long radical;
}

fn long cipolla_mod_pow(long base, long exponent, long modulus) {
    long result = 1;
    base %= modulus;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = (result * base) % modulus;
        base = (base * base) % modulus;
        exponent >>= 1;
    }
    return result;
}

fn long cipolla_legendre(long value, long prime) {
    long symbol = cipolla_mod_pow(value % prime, (prime - 1) / 2, prime);
    return symbol == prime - 1 ? -1 : symbol;
}

fn ExtensionValue cipolla_multiply(ExtensionValue left, ExtensionValue right,
                                  long radicand, long prime) {
    long real = (left.real * right.real + radicand * left.radical * right.radical) % prime;
    long radical = (left.real * right.radical + left.radical * right.real) % prime;
    return ExtensionValue{real, radical};
}

fn ExtensionValue cipolla_extension_pow(ExtensionValue base, long exponent,
                                        long radicand, long prime) {
    ExtensionValue result = ExtensionValue{1, 0};
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = cipolla_multiply(result, base, radicand, prime);
        base = cipolla_multiply(base, base, radicand, prime);
        exponent >>= 1;
    }
    return result;
}

fn long cipolla_modular_square_root(long* packed, usz length)
    @export("cipolla_modular_square_root") {
    if (packed == null || length != 2) return -1;
    long residue = packed[0], prime = packed[1];
    if (prime < 3 || prime > MAX_PRIME || (prime & 1) == 0 ||
        residue < 0 || residue >= prime) return -1;
    if (residue == 0) return 0;
    if (cipolla_legendre(residue, prime) != 1) return -1;

    for (long parameter = 0; parameter < prime; parameter += 1) {
        long radicand = (parameter * parameter - residue) % prime;
        if (radicand < 0) radicand += prime;
        if (cipolla_legendre(radicand, prime) == -1) {
            ExtensionValue root = cipolla_extension_pow(
                ExtensionValue{parameter, 1}, (prime + 1) / 2, radicand, prime);
            if (root.radical != 0) return -1;
            return root.real < prime - root.real ? root.real : prime - root.real;
        }
    }
    return -1;
}
