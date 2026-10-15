// Java-compatible low-bit mask for a signed 32-bit input and exponent 1..31.
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t modulo_power_of_two(const std::int64_t *values, std::size_t length)
{
    if (values == nullptr || length != 2) return -1;
    const std::int64_t x = values[0];
    const std::int64_t exponent = values[1];
    if (x < INT32_MIN || x > INT32_MAX || exponent < 1 || exponent > 31) return -1;
    const std::int64_t mask = (INT64_C(1) << exponent) - 1;
    return x & mask;
}
