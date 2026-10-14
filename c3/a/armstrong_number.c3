module armstrong_number;

// Exact decimal digit powers; 1 for Armstrong numbers and 0 otherwise.
fn long armstrong_number(long n) @export("armstrong_number")
{
    if (n < 0) return 0;
    if (n == 0) return 1;
    long digits = 0;
    for (long remaining = n; remaining > 0; remaining /= 10) digits++;
    long sum = 0;
    for (long remaining = n; remaining > 0; remaining /= 10) {
        long digit = remaining % 10;
        long power = 1;
        for (long exponent = 0; exponent < digits; exponent++) power *= digit;
        if (power > n - sum) return 0;
        sum += power;
    }
    return sum == n ? 1 : 0;
}
