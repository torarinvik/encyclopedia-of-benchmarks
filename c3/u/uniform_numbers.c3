module uniform_numbers;

fn long uniform_numbers(long value) @export("uniform_numbers")
{
    if (value < 0 || value > 999999999) return -1;
    long remaining = value;
    long first_digit = 0;
    long digits = 0;
    do {
        first_digit = remaining % 10;
        remaining /= 10;
        digits++;
    } while (remaining != 0);
    long repeated = 0;
    for (long index = 0; index < digits; index++) repeated = repeated * 10 + first_digit;
    long count = (digits - 1) * 9;
    return count + (repeated <= value ? first_digit : first_digit - 1);
}
