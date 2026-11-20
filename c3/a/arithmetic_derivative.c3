module arithmetic_derivative;

const usz MAX_PARSEABLE_LENGTH = 2;
const long MAX_N = 1000000000000;

fn long ad_from_factors(long n) {
    if (n < 2) return 0;
    long original = n;
    long derivative = 0;
    long factor = 2;
    while (factor <= n / factor) {
        if (n % factor == 0) {
            long exponent = 0;
            do {
                n /= factor;
                exponent += 1;
            } while (n % factor == 0);
            derivative += (original / factor) * exponent;
        }
        factor = factor == 2 ? 3 : factor + 2;
    }
    if (n > 1) derivative += original / n;
    return derivative;
}

fn long arithmetic_derivative(long* input, usz length) @export("arithmetic_derivative") {
    if (input == null || length < 1 || length > MAX_PARSEABLE_LENGTH) return -1;
    if (length != 1) return -1;
    long n = input[0];
    if (n < 0 || n > MAX_N) return -1;
    return ad_from_factors(n);
}
