#include <cstdint>

extern "C" std::int64_t problem164(std::int64_t n_digits) noexcept
{
    if (n_digits < 0 || n_digits > 26) return -1;
    if (n_digits == 0) return 1;

    std::int64_t current[100]{};
    std::int64_t next[100]{};
    for (std::int64_t first = 1; first <= 9; ++first) current[first * 10] = 1;

    for (std::int64_t used = 1; used < n_digits; ++used) {
        for (std::int64_t index = 0; index < 100; ++index) next[index] = 0;
        for (std::int64_t previous = 0; previous <= 9; ++previous) {
            for (std::int64_t before_previous = 0; before_previous <= 9; ++before_previous) {
                const auto ways = current[previous * 10 + before_previous];
                const auto maximum_digit = 9 - previous - before_previous;
                for (std::int64_t digit = 0; digit <= maximum_digit; ++digit)
                    next[digit * 10 + previous] += ways;
            }
        }
        for (std::int64_t index = 0; index < 100; ++index) current[index] = next[index];
    }

    std::int64_t total = 0;
    for (std::int64_t index = 0; index < 100; ++index) total += current[index];
    return total;
}
