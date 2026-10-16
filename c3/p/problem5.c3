module problem5;

fn long gcd(long left, long right) {
    while (right != 0) {
        long remainder = left % right;
        left = right;
        right = remainder;
    }
    return left;
}

fn long problem5(long limit) @export("problem5") {
    if (limit < 1 || limit > 20) return -1;
    long result = 1;
    for (long value = 2; value <= limit; value++) {
        result = (result / gcd(result, value)) * value;
    }
    return result;
}
