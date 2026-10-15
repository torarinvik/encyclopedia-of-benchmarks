#include <cstdint>

namespace {
constexpr std::int64_t max_index = 9999;
}

extern "C" std::int64_t divisors_count_sequence(std::int64_t index) noexcept
{
    if (index < 0 || index > max_index) return -1;
    const std::int64_t n = index + 1;
    if (n == 1) return 1;
    std::int64_t count = 2;
    for (std::int64_t k = 2; k < n; ++k) {
        if (n % k == 0) ++count;
    }
    return count;
}
