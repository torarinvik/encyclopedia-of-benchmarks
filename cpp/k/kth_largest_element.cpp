// Descending Lomuto quickselect with the final element as pivot.
#include <cstddef>
#include <cstdint>
#include <limits>

namespace { constexpr std::size_t max_length = 512; }

extern "C" std::int64_t kth_largest_element(const std::int64_t *input,
    std::size_t length) noexcept {
    if (input == nullptr || length < 2 || length > max_length + 1) return -1;
    const std::size_t count = length - 1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(count)) return -1;
    std::int32_t values[max_length];
    for (std::size_t index = 0; index < count; ++index) {
        const auto value = input[index + 1];
        if (value < std::numeric_limits<std::int32_t>::min() ||
            value > std::numeric_limits<std::int32_t>::max()) return -1;
        values[index] = static_cast<std::int32_t>(value);
    }
    const std::size_t target = static_cast<std::size_t>(input[0]) - 1;
    std::size_t low = 0, high = count - 1;
    while (low <= high) {
        const auto pivot = values[high];
        std::size_t boundary = low;
        for (std::size_t scan = low; scan < high; ++scan) {
            if (values[scan] >= pivot) {
                const auto temporary = values[boundary];
                values[boundary] = values[scan];
                values[scan] = temporary;
                ++boundary;
            }
        }
        const auto temporary = values[boundary];
        values[boundary] = values[high];
        values[high] = temporary;
        if (boundary == target) return values[boundary];
        if (boundary > target) high = boundary - 1;
        else low = boundary + 1;
    }
    return -1;
}
