/* Last ten digits of the self-powers sum for bases 1 through 1000. */
#include <cstdint>

namespace {
constexpr std::int64_t modulus = 10'000'000'000LL;
}

extern "C" std::int64_t problem48(std::int64_t ignored) noexcept
{
    if (ignored != 0) return -1;
    std::int64_t total = 0;
    for (std::int64_t base = 1; base <= 1000; ++base) {
        std::int64_t term = 1;
        for (std::int64_t exponent = 0; exponent < base; ++exponent) {
            term = (term * base) % modulus;
        }
        total = (total + term) % modulus;
    }
    return total;
}
