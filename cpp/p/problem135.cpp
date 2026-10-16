/* Count values through limit with exactly ten valid arithmetic-progression solutions. */
#include <cstdint>

namespace { constexpr std::int64_t MAX_LIMIT = 1'000'000; }

extern "C" std::int64_t problem135(std::int64_t limit) noexcept
{
    if (limit > MAX_LIMIT) return -1;
    if (limit < 0) return 0;
    std::uint8_t frequency[1'000'001]{};
    for (std::int64_t first_term = 1; first_term <= limit; ++first_term) {
        for (std::int64_t n = first_term; n <= limit; n += first_term) {
            auto common_difference = first_term + n / first_term;
            if (common_difference % 4 != 0) continue;
            common_difference /= 4;
            if (first_term > common_difference && first_term < 4 * common_difference &&
                frequency[n] < 11) ++frequency[n];
        }
    }
    std::int64_t count = 0;
    for (std::int64_t n = 1; n <= limit; ++n)
        if (frequency[n] == 10) ++count;
    return count;
}
