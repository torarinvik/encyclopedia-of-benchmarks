// Return one minus character-set Jaccard similarity for two ASCII strings.
#include <cstddef>
#include <cstdint>

namespace { constexpr double INVALID_RESULT = -1.0e300; }

extern "C" double jaccard_distance(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length < 2) return INVALID_RESULT;
    const auto left_value = values[0];
    const auto right_value = values[1];
    if (left_value < 0 || left_value > 64 || right_value < 0 || right_value > 64) return INVALID_RESULT;
    const auto left_length = static_cast<std::size_t>(left_value);
    const auto right_length = static_cast<std::size_t>(right_value);
    if (length != 2 + left_length + right_length) return INVALID_RESULT;
    for (std::size_t i = 0; i < left_length; ++i) if (values[2 + i] < 32 || values[2 + i] > 126) return INVALID_RESULT;
    for (std::size_t j = 0; j < right_length; ++j) if (values[2 + left_length + j] < 32 || values[2 + left_length + j] > 126) return INVALID_RESULT;

    std::size_t intersection = 0;
    std::size_t union_length = 0;
    for (std::size_t i = 0; i < left_length; ++i) {
        bool seen_before = false;
        for (std::size_t k = 0; k < i; ++k) if (values[2 + k] == values[2 + i]) { seen_before = true; break; }
        if (seen_before) continue;
        ++union_length;
        for (std::size_t j = 0; j < right_length; ++j) if (values[2 + i] == values[2 + left_length + j]) { ++intersection; break; }
    }
    for (std::size_t j = 0; j < right_length; ++j) {
        bool seen_before = false;
        for (std::size_t k = 0; k < j; ++k) if (values[2 + left_length + k] == values[2 + left_length + j]) { seen_before = true; break; }
        if (seen_before) continue;
        bool in_left = false;
        for (std::size_t i = 0; i < left_length; ++i) if (values[2 + i] == values[2 + left_length + j]) { in_left = true; break; }
        if (!in_left) ++union_length;
    }
    if (union_length == 0) return 0.0;
    return 1.0 - static_cast<double>(intersection) / static_cast<double>(union_length);
}
