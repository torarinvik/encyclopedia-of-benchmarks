module narcissistic_number_checker;

// Check whether n equals the sum of each decimal digit raised to digit count.
fn long narcissistic_number_checker(long n) @export("narcissistic_number_checker")
{
    if (n < -2147483648 || n > 999999) return -1;

    long original = n;
    long remaining = n;
    long digits = 0;
    while (remaining != 0) {
        digits++;
        remaining /= 10;
    }

    long sum = 0;
    while (n > 0) {
        long digit = n % 10;
        long power = 1;
        for (long exponent = 0; exponent < digits; exponent++) power *= digit;
        sum += power;
        n /= 10;
    }
    return sum == original ? 1 : 0;
}
