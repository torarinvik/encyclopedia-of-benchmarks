// Bounded unsigned modulo matching TheAlgorithms/Solidity Modulo.GetModulo.
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t modulo(const std::int64_t *values, std::size_t length)
{
    if (values == nullptr || length != 2) return -1;
    const std::int64_t a = values[0];
    const std::int64_t b = values[1];
    if (a < 0 || a > INT64_C(4294967295) || b < 1 || b > INT64_C(4294967295)) return -1;
    return a % b;
}
