/* Compute T(n) = n(n+1)/2 without an overflowing intermediate product. */
#include <cstdint>

extern "C" std::int64_t triangular_number(std::int64_t input) noexcept
{
    if (input < 0 || input > INT64_C(4294967295)) return -1;
    const auto left = input % 2 == 0 ? input / 2 : input;
    const auto right = input % 2 == 0 ? input + 1 : (input + 1) / 2;
    return left * right;
}
