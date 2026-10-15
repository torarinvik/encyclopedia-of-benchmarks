module buzz_number;

// Return 1 when n is divisible by seven or ends in decimal digit seven.
fn long buzz_number(long n) @export("buzz_number")
{
    if (n % 7 == 0) return 1;
    if (n >= 0 && n % 10 == 7) return 1;
    return 0;
}
