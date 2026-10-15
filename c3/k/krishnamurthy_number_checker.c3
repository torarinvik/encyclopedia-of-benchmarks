module krishnamurthy_number_checker;

// Check whether n equals the sum of factorials of its decimal digits.
fn long krishnamurthy_number_checker(long n) @export("krishnamurthy_number_checker")
{
    if (n < -2147483648 || n > 2147483647) return -1;
    if (n <= 0) return 0;

    long original = n;
    long sum = 0;
    while (n != 0) {
        long digit = n % 10;
        long factorial = 1;
        for (long factor = 2; factor <= digit; factor++) factorial *= factor;
        sum += factorial;
        n /= 10;
    }
    return sum == original ? 1 : 0;
}
