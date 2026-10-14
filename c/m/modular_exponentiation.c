#include <stddef.h>
#include <stdint.h>

int64_t modular_exponentiation(const int64_t *values, size_t length)
{
    if (values == NULL || length != 3) return -1;
    const int64_t base_input = values[0], exponent_input = values[1], modulus = values[2];
    if (base_input < INT64_C(-2147483648) || base_input > INT64_C(2147483647) ||
        exponent_input < 0 || exponent_input > INT64_C(2147483647) ||
        modulus < 1 || modulus > INT64_C(2147483647)) return -1;
    int64_t base = base_input % modulus;
    if (base < 0) base += modulus;
    uint64_t exponent = (uint64_t)exponent_input;
    int64_t result = INT64_C(1) % modulus;
    while (exponent != 0) {
        if ((exponent & 1U) != 0) result = (result * base) % modulus;
        base = (base * base) % modulus;
        exponent >>= 1;
    }
    return result;
}
