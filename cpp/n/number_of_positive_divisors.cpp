// Count positive divisors of the absolute value of one signed integer.
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t number_of_positive_divisors(const std::int64_t *values,
                                                     std::size_t length)
{
    if (values == nullptr || length != 1 || values[0] < -1000000000 || values[0] > 1000000000)
        return -1;
    auto remaining = values[0] < 0 ? -values[0] : values[0];
    std::int64_t count = 1;
    for (std::int64_t factor = 2; factor * factor <= remaining; ++factor) {
        std::int64_t exponent = 0;
        while (remaining % factor == 0) {
            remaining /= factor;
            ++exponent;
        }
        count *= exponent + 1;
    }
    if (remaining > 1) count *= 2;
    return count;
}
