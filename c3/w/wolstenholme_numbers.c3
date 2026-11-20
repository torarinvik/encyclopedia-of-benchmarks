module wolstenholme_numbers;

const long MAX_N = 22;
const usz MAX_PARSEABLE_LENGTH = 2;

fn long wn_gcd(long left, long right) {
    while (right != 0) {
        long remainder = left % right;
        left = right;
        right = remainder;
    }
    return left;
}

fn long wn_numerator(long n) {
    long numerator = 0;
    long denominator = 1;
    for (long k = 1; k <= n; k++) {
        long square = k * k;
        long common = wn_gcd(denominator, square);
        long scale = square / common;
        numerator = numerator * scale + denominator / common;
        denominator *= scale;
        long factor = wn_gcd(numerator, denominator);
        numerator /= factor;
        denominator /= factor;
    }
    return numerator;
}

fn long wolstenholme_numbers(long* input, usz length) @export("wolstenholme_numbers") {
    if (input == null || length < 1 || length > MAX_PARSEABLE_LENGTH) return -1;
    if (length != 1 || input[0] < 1 || input[0] > MAX_N) return -1;
    return wn_numerator(input[0]);
}
