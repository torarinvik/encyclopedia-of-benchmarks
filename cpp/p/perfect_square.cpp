/* Exact perfect-square check using bounded integer binary search. */
#include <cstdint>

extern "C" std::int64_t perfect_square(std::int64_t input) noexcept
{
    if (input < 0) return 0;
    if (input < 2) return 1;
    const auto number = static_cast<std::uint64_t>(input);
    if (((0x0213ULL >> (number & 15)) & 1) == 0) return 0;
    std::uint64_t low = 1;
    const std::uint64_t root_limit = number <= UINT32_MAX ? 65535 : 3037000499ULL;
    auto high = number / 2 < root_limit ? number / 2 : root_limit;
    while (low <= high) {
        const auto middle = (low + high) >> 1;
        const auto square = middle * middle;
        if (square == number) return 1;
        if (square < number) low = middle + 1;
        else high = middle - 1;
    }
    return 0;
}
