module gcd_of_n_numbers;

// Fold positive signed 32-bit values with Euclid's GCD algorithm.
fn long gcd_pair(long left, long right) {
    while (right != 0) {
        long remainder = left % right;
        left = right;
        right = remainder;
    }
    return left;
}

fn long gcd_of_n_numbers(long* values, usz length) @export("gcd_of_n_numbers") {
    if (length == 0 || length > 64) return -1;
    for (usz index = 0; index < length; index++) {
        if (values[index] < 1 || values[index] > 2147483647) return -1;
    }
    long result = values[0];
    for (usz index = 1; index < length && result != 1; index++) {
        result = gcd_pair(result, values[index]);
    }
    return result;
}
