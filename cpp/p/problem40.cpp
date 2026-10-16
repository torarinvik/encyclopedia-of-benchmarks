/* Product of selected Champernowne digits via decimal digit blocks. */
#include <cstdint>

namespace {
std::int64_t digit_at_position(std::int64_t position) noexcept
{
    std::int64_t digits = 1;
    std::int64_t block_count = 9;
    std::int64_t first_number = 1;
    while (position > digits * block_count) {
        position -= digits * block_count;
        ++digits;
        block_count *= 10;
        first_number *= 10;
    }
    const auto number = first_number + (position - 1) / digits;
    const auto offset = (position - 1) % digits;
    std::int64_t divisor = 1;
    for (std::int64_t power = 0; power < digits - offset - 1; ++power) divisor *= 10;
    return (number / divisor) % 10;
}
}

extern "C" std::int64_t problem40(std::int64_t ignored) noexcept
{
    if (ignored != 0) return -1;
    return digit_at_position(1) * digit_at_position(10) * digit_at_position(100) *
           digit_at_position(1000) * digit_at_position(10000) *
           digit_at_position(100000) * digit_at_position(1000000);
}
