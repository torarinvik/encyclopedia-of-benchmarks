module twin_prime;

fn bool is_prime(long value)
{
    if (value < 2) return false;
    if (value == 2) return true;
    if (value % 2 == 0) return false;
    for (long divisor = 3; divisor <= value / divisor; divisor += 2) {
        if (value % divisor == 0) return false;
    }
    return true;
}

fn long twin_prime(long value) @export("twin_prime")
{
    if (value < -4096 || value > 4096) return -1;
    if (is_prime(value) && is_prime(value + 2)) return value + 2;
    return -1;
}
