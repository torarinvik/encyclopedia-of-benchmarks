#include <cstdint>

static std::int64_t divisor_count(std::int64_t value) noexcept
{
    std::int64_t count = 1;
    for (std::int64_t factor = 2; factor <= value / factor; ++factor) {
        std::int64_t multiplicity = 0;
        while (value % factor == 0) {
            value /= factor;
            ++multiplicity;
        }
        if (multiplicity != 0) count *= multiplicity + 1;
    }
    if (value > 1) count *= 2;
    return count;
}

extern "C" std::int64_t problem12_sol1(std::int64_t threshold) noexcept
{
    if (threshold != 500) return -1;
    std::int64_t index = 1;
    std::int64_t triangular = 1;
    for (;;) {
        ++index;
        triangular += index;
        if (divisor_count(triangular) > 500) return triangular;
    }
}
