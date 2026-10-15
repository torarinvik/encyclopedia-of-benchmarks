#include <cstdint>

namespace {
constexpr std::int64_t max_index = 3810777;
}

extern "C" std::int64_t tetrahedral_sequence(std::int64_t index) noexcept
{
    if (index < 0 || index > max_index) return -1;
    std::int64_t a = index;
    std::int64_t b = index + 1;
    std::int64_t c = index + 2;
    if (a % 2 == 0) a /= 2;
    else if (b % 2 == 0) b /= 2;
    else c /= 2;
    if (a % 3 == 0) a /= 3;
    else if (b % 3 == 0) b /= 3;
    else c /= 3;
    return a * b * c;
}
