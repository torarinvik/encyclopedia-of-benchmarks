module largest_power;

fn bool largest_power_is_prime(ulong value)
{
    if (value < 2) return false;
    for (ulong divisor = 2; divisor <= value / divisor; divisor += 1) {
        if (value % divisor == 0) return false;
    }
    return true;
}

fn long largest_power(ulong n, ulong p) @export("largest_power")
{
    if (n > 4294967295 || p > 65535 || !largest_power_is_prime(p)) return -1;
    ulong quotient = n;
    long total = 0;
    while (quotient != 0) {
        quotient /= p;
        total += (long)quotient;
    }
    return total;
}
