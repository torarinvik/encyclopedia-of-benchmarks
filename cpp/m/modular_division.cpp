// Fermat modular division for a bounded prime modulus.
#include <cstddef>
#include <cstdint>

static bool modular_division_is_prime(int64_t value)
{
    if (value < 2) return false;
    for (int64_t divisor = 2; divisor <= value / divisor; ++divisor) {
        if (value % divisor == 0) return false;
    }
    return true;
}

static int64_t modular_division_power(int64_t base, uint64_t exponent, int64_t modulus)
{
    int64_t result = 1;
    base %= modulus;
    while (exponent != 0) {
        if ((exponent & 1U) != 0) result = (result * base) % modulus;
        exponent >>= 1;
        base = (base * base) % modulus;
    }
    return result;
}

extern "C" int64_t modular_division(const int64_t *values, size_t length)
{
    if (values == nullptr || length != 3) return -1;
    const int64_t numerator = values[0];
    const int64_t denominator = values[1];
    const int64_t modulus = values[2];
    if (numerator < 0 || numerator > INT64_C(1000000000000) ||
        denominator < 0 || denominator > INT64_C(1000000000000) ||
        modulus < 2 || modulus > 1000000 || !modular_division_is_prime(modulus) ||
        denominator % modulus == 0) return -1;
    const int64_t inverse = modular_division_power(denominator, static_cast<uint64_t>(modulus - 2), modulus);
    return ((numerator % modulus) * inverse) % modulus;
}
