module next_prime_number;

fn bool is_candidate_prime(uint value)
{
    if (value % 3 == 0) return false;
    for (uint divisor = 5; divisor * divisor <= value; divisor += 6) {
        if (value % divisor == 0 || value % (divisor + 2) == 0) return false;
    }
    return true;
}

// Find the smallest prime strictly greater than the input.
fn long next_prime_number(long value) @export("next_prime_number")
{
    if (value < -4096 || value > 4096) return -1;
    if (value < 2) return 2;
    if (value == 2) return 3;
    uint candidate = (uint)(value + 1) | 1;
    while (!is_candidate_prime(candidate)) candidate += 2;
    return (long)candidate;
}
