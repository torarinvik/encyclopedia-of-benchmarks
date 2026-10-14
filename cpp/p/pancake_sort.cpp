/* Independent portable implementation of TheAlgorithms/C pancake sort. */
#include <cstddef>
#include <cstdint>

static void flip_prefix(std::int64_t *values, std::size_t last) noexcept
{
    std::size_t first = 0;
    while (first < last) {
        const std::int64_t temporary = values[first];
        values[first] = values[last];
        values[last] = temporary;
        ++first;
        --last;
    }
}

extern "C" void pancake_sort(std::int64_t *values, std::size_t length) noexcept
{
    for (std::size_t prefix = length; prefix > 1; --prefix) {
        std::size_t maximum = 0;
        for (std::size_t probe = 1; probe < prefix; ++probe) {
            if (values[probe] > values[maximum]) maximum = probe;
        }
        if (maximum != prefix - 1) {
            flip_prefix(values, maximum);
            flip_prefix(values, prefix - 1);
        }
    }
}
