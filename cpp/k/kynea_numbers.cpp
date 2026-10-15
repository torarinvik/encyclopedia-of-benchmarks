#include <cstdint>

extern "C" std::int64_t kynea_numbers(std::int64_t index) noexcept
{
    if (index < 1 || index > 31) return -1;
    std::int64_t value = (INT64_C(1) << index) + 1;
    std::int64_t square = value * value;
    return square - 2;
}
