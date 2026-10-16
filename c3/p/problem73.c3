module problem73;

const long MAX_DENOMINATOR = 12000;

fn long gcd_i64(long left, long right) {
    while (right != 0) {
        long remainder = left % right;
        left = right;
        right = remainder;
    }
    return left;
}

fn long problem73(long max_denominator) @export("problem73") {
    if (max_denominator < 0 || max_denominator > MAX_DENOMINATOR) return -1;
    long count = 0;
    for (long denominator = 0; denominator <= max_denominator; ++denominator) {
        long numerator_start = denominator / 3 + 1;
        long numerator_step = 1;
        if (denominator % 2 == 0) {
            numerator_start += 1 - numerator_start % 2;
            numerator_step = 2;
        }
        long numerator_end = (denominator + 1) / 2;
        for (long numerator = numerator_start; numerator < numerator_end;
             numerator += numerator_step) {
            if (gcd_i64(numerator, denominator) == 1) ++count;
        }
    }
    return count;
}
