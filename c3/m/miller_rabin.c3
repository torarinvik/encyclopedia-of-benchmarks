module miller_rabin;

// Deterministic Miller-Rabin for signed 32-bit inputs.
fn long mod_power(long base, long exponent, long modulus)
{
    long result = 1;
    base = base % modulus;
    while (exponent > 0) {
        if (exponent % 2 != 0) result = (result * base) % modulus;
        base = (base * base) % modulus;
        exponent = exponent / 2;
    }
    return result;
}

fn bool passes_base(long n, long base, long odd_part, long powers_of_two)
{
    long value = mod_power(base, odd_part, n);
    if (value == 1 || value == n - 1) return true;
    for (long round = 1; round < powers_of_two; round += 1) {
        value = (value * value) % n;
        if (value == n - 1) return true;
    }
    return false;
}

fn long miller_rabin(long n) @export("miller_rabin")
{
    if (n < 2) return 0;
    if (n > 2147483647) return -1;
    if (n == 2 || n == 3 || n == 5 || n == 7) return 1;
    if (n % 2 == 0 || n % 3 == 0 || n % 5 == 0 || n % 7 == 0) return 0;

    long odd_part = n - 1;
    long powers_of_two = 0;
    while (odd_part % 2 == 0) {
        odd_part = odd_part / 2;
        powers_of_two += 1;
    }
    if (!passes_base(n, 2, odd_part, powers_of_two)) return 0;
    if (!passes_base(n, 3, odd_part, powers_of_two)) return 0;
    if (!passes_base(n, 5, odd_part, powers_of_two)) return 0;
    if (!passes_base(n, 7, odd_part, powers_of_two)) return 0;
    return 1;
}
