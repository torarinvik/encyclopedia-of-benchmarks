module shors_algorithm;

const long MIN_MODULUS = 2;
const long MAX_MODULUS = 255;
const long MIN_ATTEMPTS = 1;
const long MAX_ATTEMPTS = 16;
const long INVALID_RESULT = -1;

fn long gcd_i64(long a, long b) {
    while (b != 0) {
        long remainder = a % b;
        a = b;
        b = remainder;
    }
    return a;
}

fn long shors_algorithm(long* packed, usz length) @export("shors_algorithm") {
    if (packed == null || length < 3 || length > 19) return INVALID_RESULT;
    long modulus = packed[0];
    long attempts = packed[1];
    if (modulus < MIN_MODULUS || modulus > MAX_MODULUS || attempts < MIN_ATTEMPTS || attempts > MAX_ATTEMPTS || length != (usz)(2 + attempts)) return INVALID_RESULT;
    for (long index = 0; index < attempts; index++) {
        long base = packed[2 + (usz)index];
        if (base < 2 || base > modulus) return INVALID_RESULT;
    }

    for (long index = 0; index < attempts; index++) {
        long base = packed[2 + (usz)index];
        long common = gcd_i64(base, modulus);
        if (common != 1) return common;
        long order = 1;
        long power = base % modulus;
        while (power != 1 && order < modulus - 1) {
            power = (power * base) % modulus;
            order++;
        }
        if (power != 1) return INVALID_RESULT;
        if (order % 2 == 1) continue;

        long half_power = 1;
        for (long exponent = 0; exponent < order / 2; exponent++) {
            half_power = (half_power * base) % modulus;
        }
        long upper = half_power + 1;
        long lower = half_power - 1;
        if (upper % modulus == 0 || lower % modulus == 0) continue;
        long upper_gcd = gcd_i64(upper, modulus);
        if (upper_gcd != 1) return upper_gcd;
        return gcd_i64(lower, modulus);
    }
    return INVALID_RESULT;
}
