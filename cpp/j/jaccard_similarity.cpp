// Return intersection-over-union similarity for two unique ASCII sets.
#include <cstddef>
#include <cstdint>

namespace { constexpr double INVALID_RESULT = -1.0e300; }

extern "C" double jaccard_similarity(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length < 2) return INVALID_RESULT;
    const auto left_value = values[0];
    const auto right_value = values[1];
    if (left_value < 0 || left_value > 64 || right_value < 0 || right_value > 64 ||
        (left_value == 0 && right_value == 0)) return INVALID_RESULT;
    const auto left_length = static_cast<std::size_t>(left_value);
    const auto right_length = static_cast<std::size_t>(right_value);
    if (length != 2 + left_length + right_length) return INVALID_RESULT;

    for (std::size_t i = 0; i < left_length; ++i) {
        const auto value = values[2 + i];
        if (value < 32 || value > 126) return INVALID_RESULT;
        for (std::size_t before = 0; before < i; ++before)
            if (values[2 + before] == value) return INVALID_RESULT;
    }
    for (std::size_t i = 0; i < right_length; ++i) {
        const auto value = values[2 + left_length + i];
        if (value < 32 || value > 126) return INVALID_RESULT;
        for (std::size_t before = 0; before < i; ++before)
            if (values[2 + left_length + before] == value) return INVALID_RESULT;
    }

    std::size_t intersection = 0;
    for (std::size_t i = 0; i < left_length; ++i)
        for (std::size_t j = 0; j < right_length; ++j)
            if (values[2 + i] == values[2 + left_length + j]) { ++intersection; break; }
    const auto union_length = left_length + right_length - intersection;
    return static_cast<double>(intersection) / static_cast<double>(union_length);
}
