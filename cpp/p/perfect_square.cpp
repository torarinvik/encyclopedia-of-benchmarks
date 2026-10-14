/* Exact perfect-square check using integer binary search and division. */
#include <cstdint>

extern "C" std::int64_t perfect_square(std::int64_t input) noexcept
{
    if (input < 0) return 0;
    if (input < 2) return 1;
    const auto number = static_cast<std::uint64_t>(input);
    std::uint64_t low = 1;
    std::uint64_t high = number / 2;
    while (low <= high) {
        const auto middle = low + (high - low) / 2;
        const auto quotient = number / middle;
        if (quotient == middle) {
            if (number % middle == 0) return 1;
            low = middle + 1;
        } else if (quotient < middle) {
            high = middle - 1;
        } else {
            low = middle + 1;
        }
    }
    return 0;
}
