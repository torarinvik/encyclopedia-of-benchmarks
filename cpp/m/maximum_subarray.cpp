/* Kadane's maximum nonempty contiguous-subarray sum. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t maximum_subarray(const std::int64_t *values,
                                          std::size_t length) noexcept
{
    if (length == 0 || length > 1024) return -1;
    for (std::size_t index = 0; index < length; ++index) {
        if (values[index] < INT32_MIN || values[index] > INT32_MAX) return -1;
    }
    auto current = values[0];
    auto best = current;
    for (std::size_t index = 1; index < length; ++index) {
        current = current > 0 ? current + values[index] : values[index];
        if (current > best) best = current;
    }
    return best;
}
