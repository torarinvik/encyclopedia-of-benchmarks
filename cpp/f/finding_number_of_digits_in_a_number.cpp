#include <cstdint>

extern "C" std::int64_t finding_number_of_digits_in_a_number(std::int64_t value) noexcept
{
    if (value < 0) return -1;
    std::uint64_t remaining = static_cast<std::uint64_t>(value);
    std::int64_t count = 0;
    while (remaining != 0) {
        remaining /= 10;
        ++count;
    }
    return count;
}
