#include <array>
#include <cstdint>
#include <cstddef>

namespace {
bool source_sieve_flag(std::int64_t value)
{
    if (value < 2) return true;
    for (std::int64_t divisor = 2; divisor <= value / divisor; ++divisor) {
        if (value % divisor == 0) return false;
    }
    return true;
}
} // namespace

extern "C" std::int64_t sphenic_number(std::int64_t value) noexcept
{
    if (value < 0 || value > 1000) return -1;
    std::array<std::int64_t, 3> first{};
    std::int64_t count = 0;
    for (std::int64_t divisor = 1; divisor <= value; ++divisor) {
        if (value % divisor == 0 && count < 9) {
            if (count < 3) first[static_cast<std::size_t>(count)] = divisor;
            ++count;
        }
    }
    return count == 8 && source_sieve_flag(first[0])
        && source_sieve_flag(first[1]) && source_sieve_flag(first[2]);
}
