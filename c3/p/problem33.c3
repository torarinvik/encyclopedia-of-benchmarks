module problem33;

fn long gcd_i64(long left, long right) {
    while (right != 0) {
        long remainder = left % right;
        left = right;
        right = remainder;
    }
    return left;
}

fn long problem33(long digit_len) @export("problem33") {
    if (digit_len < 0 || digit_len > 5) return -1;
    long upper = 1;
    for (long index = 0; index < digit_len; index++) upper *= 10;

    double result = 1.0;
    long denominator = 11;
    for (long numerator = 11; numerator < upper; numerator++) {
        while (denominator <= 99) {
            if (numerator != denominator && numerator % 10 == denominator / 10 &&
                denominator % 10 != 0 &&
                (double)(numerator / 10) / (double)(denominator % 10) ==
                    (double)numerator / (double)denominator) {
                long divisor = gcd_i64(numerator, denominator);
                result *= (double)(denominator / divisor) / (double)(numerator / divisor);
            }
            denominator++;
        }
        denominator = 10;
    }
    return (long)result;
}
