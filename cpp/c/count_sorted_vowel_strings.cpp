#include <cstdint>

namespace { constexpr std::int64_t MAX_INPUT = 30'000; }

// Count nondecreasing vowel strings via the pinned closed-form product.
extern "C" std::int64_t count_sorted_vowel_strings(std::int64_t n) noexcept
{
    if (n < 0 || n > MAX_INPUT) return -1;
    return (n + 4) * (n + 3) * (n + 2) * (n + 1) / 24;
}
