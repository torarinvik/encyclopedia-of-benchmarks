/* Maximum product of a nonempty contiguous subarray. */
#include <algorithm>
#include <cstddef>
#include <cstdint>

namespace { constexpr std::int64_t invalid_result = -9'223'372'036'854'775'807LL - 1; }

extern "C" std::int64_t maximum_product_subarray(const std::int64_t *values,
                                                    std::size_t length) noexcept
{
    if (values == nullptr || length == 0 || length > 9) return invalid_result;
    for (std::size_t index = 0; index < length; ++index) {
        if (values[index] < -10 || values[index] > 10) return invalid_result;
    }

    std::int64_t current_max = values[0], current_min = values[0], best = values[0];
    for (std::size_t index = 1; index < length; ++index) {
        const std::int64_t value = values[index];
        const std::int64_t prior_max = current_max;
        const std::int64_t prior_min = current_min;
        const std::int64_t from_max = prior_max * value;
        const std::int64_t from_min = prior_min * value;
        current_max = std::max(value, std::max(from_max, from_min));
        current_min = std::min(value, std::min(from_max, from_min));
        best = std::max(best, current_max);
    }
    return best;
}
