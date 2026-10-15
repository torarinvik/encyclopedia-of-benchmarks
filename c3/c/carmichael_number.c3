module carmichael_number;

fn bool is_composite(long n) {
    if (n < 4) return false;
    for (long divisor = 2; divisor <= n / divisor; divisor++) {
        if (n % divisor == 0) return true;
    }
    return false;
}

fn long modular_power(long base, long exponent, long modulus) {
    if (exponent == 0) return 1;
    long half = modular_power(base, exponent / 2, modulus) % modulus;
    long result = (half * half) % modulus;
    if (exponent % 2 != 0) result = (result * base) % modulus;
    return result;
}

fn long gcd(long left, long right) {
    while (right != 0) {
        long remainder = left % right;
        left = right;
        right = remainder;
    }
    return left;
}

fn long carmichael_number(long value) @export("carmichael_number") {
    if (value < 1 || value > 10000) return -1;
    if (value < 3 || !is_composite(value)) return 0;
    for (long base = 2; base < value; base++) {
        if (gcd(base, value) == 1 && modular_power(base, value - 1, value) != 1) return 0;
    }
    return 1;
}
