/* Find the first odd prime index whose source remainder exceeds the limit. */
#include <cstdint>

namespace { constexpr std::int64_t MAX_LIMIT = 10'000'000'000; constexpr std::int64_t PRIME_LIMIT = 300'000; }

extern "C" std::int64_t problem123(std::int64_t limit) noexcept
{
    if (limit > MAX_LIMIT) return -1;
    bool composite[PRIME_LIMIT + 1]{};
    for (std::int64_t factor = 2; factor * factor <= PRIME_LIMIT; ++factor)
        if (!composite[factor])
            for (std::int64_t multiple = factor * factor; multiple <= PRIME_LIMIT; multiple += factor)
                composite[multiple] = true;
    std::int64_t n = 1;
    bool skip_next = false;
    for (std::int64_t candidate = 2; candidate <= PRIME_LIMIT; ++candidate) {
        if (composite[candidate]) continue;
        if (skip_next) { skip_next = false; continue; }
        if (2 * candidate * n > limit) return n;
        skip_next = true;
        n += 2;
    }
    return -1;
}
