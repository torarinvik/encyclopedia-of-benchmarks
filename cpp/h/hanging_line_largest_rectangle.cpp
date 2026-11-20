#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_length = 64;
constexpr std::int64_t max_height = 1'000'000;
constexpr std::int64_t invalid_result = INT64_MIN;
}

extern "C" std::int64_t hanging_line_largest_rectangle(const std::int64_t* heights,
                                                        std::size_t length) noexcept {
    if (length == 0) return 0;
    if (heights == nullptr || length > max_length) return invalid_result;
    for (std::size_t i = 0; i < length; ++i) {
        if (heights[i] < 0 || heights[i] > max_height) return invalid_result;
    }

    std::array<std::size_t, max_length> left{};
    std::array<std::size_t, max_length> right{};
    for (std::size_t i = 0; i < length; ++i) {
        left[i] = i;
        while (left[i] > 0 && heights[i] <= heights[left[i] - 1])
            left[i] = left[left[i] - 1];
    }
    for (std::size_t i = length; i-- > 0;) {
        right[i] = i;
        while (right[i] + 1 < length && heights[i] <= heights[right[i] + 1])
            right[i] = right[right[i] + 1];
    }

    std::int64_t best = 0;
    for (std::size_t i = 0; i < length; ++i) {
        const auto width = static_cast<std::int64_t>(right[i] - left[i] + 1);
        const auto area = heights[i] * width;
        if (area > best) best = area;
    }
    return best;
}
