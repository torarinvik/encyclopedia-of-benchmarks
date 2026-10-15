// Return the zero-based 5-smooth number at index n.
#include <cstdint>

extern "C" std::int64_t nth_ugly_number(std::int64_t n)
{
    if (n < 0 || n > 12690) return -1;

    std::int64_t values[12691]{};
    values[0] = 1;
    std::int64_t i2 = 0, i3 = 0, i5 = 0;
    for (std::int64_t index = 1; index <= n; ++index) {
        const std::int64_t c2 = 2 * values[i2];
        const std::int64_t c3 = 3 * values[i3];
        const std::int64_t c5 = 5 * values[i5];
        std::int64_t next = c2 < c3 ? c2 : c3;
        if (c5 < next) next = c5;
        values[index] = next;
        if (c2 == next) ++i2;
        if (c3 == next) ++i3;
        if (c5 == next) ++i5;
    }
    return values[n];
}
