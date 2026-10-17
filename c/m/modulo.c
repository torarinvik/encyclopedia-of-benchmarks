/* Bounded unsigned modulo matching TheAlgorithms/Solidity Modulo.GetModulo. */
#include <stddef.h>
#include <stdint.h>

int64_t modulo(const int64_t *values, size_t length)
{
    if (values == NULL || length != 2) return -1;
    const int64_t a = values[0];
    const int64_t b = values[1];
    if (a < 0 || a > INT64_C(4294967295) || b < 1 || b > INT64_C(4294967295)) return -1;
    return a % b;
}
