// Find the numerator of the closest bounded fraction below a reduced target.
module problem71;

const long MAX_DENOMINATOR = 1000000;

fn long gcd_positive(long left, long right) {
    while (right != 0) {
        long remainder = left % right;
        left = right;
        right = remainder;
    }
    return left;
}

fn long problem71(long* input, usz length) @export("problem71") {
    if (input == null || length != 3) return -1;
    long target_numerator = input[0];
    long target_denominator = input[1];
    long limit = input[2];
    if (target_numerator < 1 || target_denominator <= target_numerator ||
        target_denominator > MAX_DENOMINATOR || limit < 1 || limit > MAX_DENOMINATOR ||
        gcd_positive(target_numerator, target_denominator) != 1) return -1;

    long best_numerator = 0;
    long best_denominator = 1;
    for (long current_denominator = 1; current_denominator <= limit; current_denominator++) {
        long current_numerator = current_denominator * target_numerator / target_denominator;
        if (current_denominator % target_denominator == 0) current_numerator--;
        if (current_numerator * best_denominator > current_denominator * best_numerator) {
            best_numerator = current_numerator;
            best_denominator = current_denominator;
        }
    }
    return best_numerator;
}
