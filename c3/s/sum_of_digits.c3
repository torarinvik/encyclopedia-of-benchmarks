module sum_of_digits;

// Add the decimal digits of the absolute value of a signed 32-bit integer.
fn long sum_of_digits(long input) @export("sum_of_digits")
{
    if (input < -2147483648 || input > 2147483647) return -1;
    ulong remaining = input < 0 ? (ulong)(-input) : (ulong)input;
    long total = 0;
    while (remaining != 0) {
        total += (long)(remaining % 10);
        remaining /= 10;
    }
    return total;
}
