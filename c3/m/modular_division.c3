module modular_division;

fn bool modular_division_is_prime(long value)
{
    if (value < 2) return false;
    for (long divisor = 2; divisor <= value / divisor; divisor += 1) {
        if (value % divisor == 0) return false;
    }
    return true;
}

fn long modular_division_power(long base, ulong exponent, long modulus)
{
    long result = 1;
    base %= modulus;
    while (exponent != 0) {
        if ((exponent & 1ul) != 0ul) result = (result * base) % modulus;
        exponent >>= 1;
        base = (base * base) % modulus;
    }
    return result;
}

fn long modular_division(long* values, usz length) @export("modular_division")
{
    if (values == null || length != 3) return -1;
    long numerator = values[0];
    long denominator = values[1];
    long modulus = values[2];
    if (numerator < 0 || numerator > 1000000000000 ||
        denominator < 0 || denominator > 1000000000000 ||
        modulus < 2 || modulus > 1000000 || !modular_division_is_prime(modulus) ||
        denominator % modulus == 0) return -1;
    long inverse = modular_division_power(denominator, (ulong)(modulus - 2), modulus);
    return ((numerator % modulus) * inverse) % modulus;
}
