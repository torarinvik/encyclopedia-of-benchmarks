/* Return the longest strictly increasing contiguous run. */
#include <cstddef>
#include <cstdint>

namespace { constexpr std::size_t max_length = 10000; }

extern "C" std::int64_t longest_continuous_increasing_subsequence(
        const std::int64_t *values, std::size_t length) noexcept {
    if (length > max_length || (length != 0 && values == nullptr)) return -1;
    for (std::size_t index = 0; index < length; ++index)
        if (values[index] < -1000000 || values[index] > 1000000) return -1;
    if (length == 0) return 0;

    std::size_t current = 1, best = 1;
    for (std::size_t index = 1; index < length; ++index) {
        if (values[index] > values[index - 1]) ++current;
        else current = 1;
        if (current > best) best = current;
    }
    return static_cast<std::int64_t>(best);
}
