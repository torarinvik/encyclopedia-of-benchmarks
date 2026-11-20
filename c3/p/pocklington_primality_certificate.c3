module pocklington_primality_certificate;

const long MAX_N = 65535;
const long MAX_FACTORS = 6;
const long MAX_EXPONENT = 16;
const usz MAX_LENGTH = 22;

fn long gcd_i64(long left, long right) {
    while (right != 0) {
        long remainder = left % right;
        left = right;
        right = remainder;
    }
    return left;
}

fn bool is_prime(long value) {
    if (value < 2) return false;
    for (long divisor = 2; divisor * divisor <= value; divisor = divisor == 2 ? 3 : divisor + 2) {
        if (value % divisor == 0) return false;
    }
    return true;
}

fn long pow_mod(long base, long exponent, long modulus) {
    long result = 1;
    long factor = base % modulus;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = (result * factor) % modulus;
        factor = (factor * factor) % modulus;
        exponent >>= 1;
    }
    return result;
}

fn long verify_certificate(long* values, usz length) {
    if (values == null || length < 2 || length > MAX_LENGTH) return -1;
    long n = values[0];
    long count = values[1];
    if (n < 3 || n > MAX_N || count < 1 || count > MAX_FACTORS) return -1;
    if (length != (usz)(3 + 3 * count)) return -1;

    long factored_part = 1;
    long previous_prime = 1;
    for (long index = 0; index < count; index++) {
        usz offset = (usz)(2 + 3 * index);
        long prime = values[offset];
        long exponent = values[offset + 1];
        long witness = values[offset + 2];
        if (prime <= previous_prime || prime < 2 || exponent < 1 || exponent > MAX_EXPONENT
            || witness < 1 || witness >= n || !is_prime(prime)) return -1;
        previous_prime = prime;
        for (long power = 0; power < exponent; power++) {
            if (factored_part > (n - 1) / prime) return -1;
            factored_part *= prime;
        }
    }
    long cofactor = values[2 + 3 * count];
    if (cofactor < 1 || cofactor >= n || factored_part * cofactor != n - 1) return -1;
    if (factored_part * factored_part <= n) return 0;

    for (long index = 0; index < count; index++) {
        usz offset = (usz)(2 + 3 * index);
        long prime = values[offset];
        long witness = values[offset + 2];
        if (pow_mod(witness, n - 1, n) != 1) return 0;
        long reduced = pow_mod(witness, (n - 1) / prime, n);
        long difference = (reduced + n - 1) % n;
        if (gcd_i64(difference, n) != 1) return 0;
    }
    return 1;
}

fn long pocklington_primality_certificate(long* input, usz length)
        @export("pocklington_primality_certificate") {
    return verify_certificate(input, length);
}
