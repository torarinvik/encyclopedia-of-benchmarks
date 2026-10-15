// Exact square-pyramidal sum within the pinned u64 intermediate range.
#include <cstdint>

extern "C" std::int64_t square_pyramidal_numbers(std::int64_t n)
{
    if (n < 0 || n > 2'097'151) return -1;
    const auto value = static_cast<std::uint64_t>(n);
    const std::uint64_t numerator = value * (value + 1) * (2 * value + 1);
    return static_cast<std::int64_t>(numerator / 6);
}
