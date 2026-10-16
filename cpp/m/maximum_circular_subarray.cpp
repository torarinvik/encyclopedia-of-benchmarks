/* Kadane-based maximum nonempty contiguous circular-subarray sum. */
#include <cstddef>
#include <cstdint>

namespace { constexpr std::int64_t invalid_result = -9'223'372'036'854'775'807LL - 1; }

extern "C" std::int64_t maximum_circular_subarray(const std::int64_t *values,
                                                    std::size_t length) noexcept
{
    if (values == nullptr || length == 0 || length > 64) return invalid_result;
    for (std::size_t index = 0; index < length; ++index) {
        if (values[index] < -1'000'000 || values[index] > 1'000'000) return invalid_result;
    }

    std::int64_t total = values[0];
    std::int64_t current_max = values[0], max_so_far = values[0];
    std::int64_t current_min = values[0], min_so_far = values[0];
    for (std::size_t index = 1; index < length; ++index) {
        const std::int64_t value = values[index];
        current_max = current_max + value > value ? current_max + value : value;
        max_so_far = max_so_far > current_max ? max_so_far : current_max;
        current_min = current_min + value < value ? current_min + value : value;
        min_so_far = min_so_far < current_min ? min_so_far : current_min;
        total += value;
    }
    if (min_so_far == total) return max_so_far;
    return max_so_far > total - min_so_far ? max_so_far : total - min_so_far;
}
