// Return the longest run of ones in a binary array.
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t max_consecutive_ones(const std::int64_t *values, std::size_t length)
{
    if (length > 4096) return -1;
    std::size_t best = 0;
    std::size_t run = 0;
    for (std::size_t index = 0; index < length; ++index) {
        if (values[index] != 0 && values[index] != 1) return -1;
        if (values[index] == 1) {
            ++run;
            if (run > best) best = run;
        } else {
            run = 0;
        }
    }
    return static_cast<std::int64_t>(best);
}
