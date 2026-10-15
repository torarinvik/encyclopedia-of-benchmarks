/* Compute the central polygonal number n(n+1)/2 + 1 safely. */
#include <cstdint>

extern "C" std::int64_t central_polygonal_numbers_sequence(std::int64_t input) noexcept
{
    if (input < 0 || input > INT64_C(4294967295)) return -1;
    const auto left = input % 2 == 0 ? input / 2 : input;
    const auto right = input % 2 == 0 ? input + 1 : (input + 1) / 2;
    return left * right + 1;
}
