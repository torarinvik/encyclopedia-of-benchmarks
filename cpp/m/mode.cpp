/* Find the unique mode of a bounded array of small nonnegative integers. */
#include <array>
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t mode(const std::int64_t *values, std::size_t length)
{
    if (values == nullptr || length == 0 || length > 4096) return -1;
    std::array<std::size_t, 256> counts{};
    for (std::size_t i = 0; i < length; ++i) {
        if (values[i] < 0 || values[i] > 255) return -1;
        ++counts[static_cast<std::size_t>(values[i])];
    }
    std::size_t maximum = 0;
    std::int64_t result = -1;
    bool unique = true;
    for (std::size_t i = 0; i < counts.size(); ++i) {
        if (counts[i] > maximum) {
            maximum = counts[i];
            result = static_cast<std::int64_t>(i);
            unique = true;
        } else if (counts[i] != 0 && counts[i] == maximum) {
            unique = false;
        }
    }
    return unique ? result : -1;
}
