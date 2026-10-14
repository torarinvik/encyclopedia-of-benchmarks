module catalan_number;

fn long gcd_i64(long left, long right)
{
    while (right != 0) {
        long remainder = left % right;
        left = right;
        right = remainder;
    }
    return left;
}

// Return the exact zero-based Catalan number through the signed 64-bit range.
fn long catalan_number(long n) @export("catalan_number")
{
    if (n < 0 || n > 35) return -1;
    long value = 1;
    for (long index = 1; index <= n; index++) {
        long numerator = 4 * index - 2;
        long denominator = index + 1;
        long common = gcd_i64(numerator, denominator);
        numerator /= common;
        denominator /= common;
        value = (value / denominator) * numerator;
    }
    return value;
}
