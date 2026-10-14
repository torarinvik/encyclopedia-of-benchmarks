/* Return the signed 64-bit magnitude, or -1 when it cannot be represented. */
#include <cstdint>

extern "C" std::int64_t abs_i64(std::int64_t input) noexcept
{
    if (input == INT64_MIN) return -1;
    return input < 0 ? -input : input;
}
