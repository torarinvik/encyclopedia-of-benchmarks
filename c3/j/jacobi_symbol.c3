module jacobi_symbol;

const long JACOBI_MAX_MODULUS = 1000000000;
const usz JACOBI_MAX_LENGTH = 3;

fn long jacobi_reciprocity(long numerator, long denominator) {
    long sign = 1;
    while (numerator != 0) {
        while ((numerator & 1) == 0) {
            numerator /= 2;
            if (denominator % 8 == 3 || denominator % 8 == 5) sign = -sign;
        }
        if (numerator % 4 == 3 && denominator % 4 == 3) sign = -sign;
        long old_numerator = numerator;
        numerator = denominator;
        denominator = old_numerator;
        numerator %= denominator;
    }
    return denominator == 1 ? sign : 0;
}

fn long jacobi_symbol(long* input, usz length) @export("jacobi_symbol") {
    if (input == null || length < 2 || length > JACOBI_MAX_LENGTH) return -1;
    long numerator = input[0];
    long denominator = input[1];
    if (denominator < 1 || denominator > JACOBI_MAX_MODULUS || (denominator & 1) == 0 ||
        numerator < 0 || numerator >= denominator || length != 2) return -1;
    return jacobi_reciprocity(numerator, denominator) + 1;
}
