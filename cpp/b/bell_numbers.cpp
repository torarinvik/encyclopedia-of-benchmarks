// Return the exact Bell number for indices that fit in signed 64-bit output.
#include <cstdint>

extern "C" std::int64_t bell_numbers(std::int64_t n) noexcept
{
    if (n < 0 || n > 25) return -1;
    if (n == 0) return 1;

    std::int64_t row[26] = {};
    row[0] = 1;
    for (std::int64_t current = 1; current < n; ++current) {
        const std::int64_t previous_first = row[0];
        const std::int64_t previous_last = row[current - 1];
        row[0] = previous_last;
        std::int64_t previous_old = previous_first;
        for (std::int64_t column = 1; column <= current; ++column) {
            const std::int64_t old_value = column < current ? row[column] : 0;
            row[column] = row[column - 1] + previous_old;
            previous_old = old_value;
        }
    }
    return row[n - 1];
}
