module problem12;

fn long divisor_count(long value) {
    long count = 1;
    for (long factor = 2; factor <= value / factor; factor++) {
        if (value % factor == 0) {
            long exponent = 0;
            do {
                value /= factor;
                exponent++;
            } while (value % factor == 0);
            count *= exponent + 1;
        }
    }
    if (value > 1) count *= 2;
    return count;
}

fn long problem12(long minimum_divisors) @export("problem12") {
    if (minimum_divisors < 0 || minimum_divisors > 500) return -1;
    for (long index = 1; index <= 12375; index++) {
        long left = index;
        long right = index + 1;
        if (index % 2 == 0) left /= 2;
        else right /= 2;
        if (divisor_count(left) * divisor_count(right) >= minimum_divisors)
            return index * (index + 1) / 2;
    }
    return -1;
}
