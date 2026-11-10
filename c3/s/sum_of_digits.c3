module sum_of_digits;

// Add the decimal digits of the absolute value of a signed 32-bit integer.
fn long sum_of_digits(long input) @export("sum_of_digits")
{
    if (input < -2147483648 || input > 2147483647) return -1;
    uint magnitude = (uint)(input < 0 ? -input : input);
    uint remaining = magnitude;
    uint total = 0;
    while (remaining >= 10) {
        uint next_quotient = remaining / 10;
        remaining /= 100;
        total += next_quotient + remaining;
    }
    return (long)(magnitude - 9 * total);
}
