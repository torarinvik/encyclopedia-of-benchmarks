/* Divide-and-conquer maximum nonempty contiguous-subarray sum. */
#include <cstddef>
#include <cstdint>

static std::int64_t max_subarray_range(const std::int64_t *values,
                                       std::size_t start, std::size_t end)
{
    if (end - start == 1) return values[start];
    const auto middle = start + (end - start) / 2;
    const auto left_best = max_subarray_range(values, start, middle);
    const auto right_best = max_subarray_range(values, middle, end);
    auto running = values[middle - 1];
    auto left_suffix = running;
    for (auto index = middle - 1; index > start;) {
        --index;
        running += values[index];
        if (running > left_suffix) left_suffix = running;
    }
    running = values[middle];
    auto right_prefix = running;
    for (auto index = middle + 1; index < end; ++index) {
        running += values[index];
        if (running > right_prefix) right_prefix = running;
    }
    const auto crossing = left_suffix + right_prefix;
    const auto best = left_best > right_best ? left_best : right_best;
    return crossing > best ? crossing : best;
}

extern "C" std::int64_t max_subarray(const std::int64_t *values,
                                      std::size_t length) noexcept
{
    if (length == 0 || length > 1024) return -1;
    for (std::size_t index = 0; index < length; ++index) {
        if (values[index] < INT32_MIN || values[index] > INT32_MAX) return -1;
    }
    return max_subarray_range(values, 0, length);
}
