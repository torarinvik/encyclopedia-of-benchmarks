module next_prime_number;

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

// Find the smallest prime strictly greater than the input.
fn long next_prime_number(long value) @export("next_prime_number")
{
    if (value < -4096 || value > 4096) return -1;
    long candidate = value + 1;
    if (candidate < 2) candidate = 2;
    while (!is_prime(candidate)) candidate++;
    return candidate;
}
