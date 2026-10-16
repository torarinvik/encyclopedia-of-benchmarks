#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_string_length = 64;
constexpr std::size_t max_input_length = 132;
constexpr std::size_t alphabet_size = 95;
constexpr double invalid_result = -1.0e300;
}

extern "C" double cosine_similarity(const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length < 2 || length > max_input_length) return invalid_result;
    if (input[0] < 0 || input[0] > static_cast<std::int64_t>(max_string_length)
            || input[1] < 0 || input[1] > static_cast<std::int64_t>(max_string_length)) return invalid_result;
    const auto left_length = static_cast<std::size_t>(input[0]);
    const auto right_length = static_cast<std::size_t>(input[1]);
    if (length != 2 + left_length + right_length) return invalid_result;

    std::uint64_t left_counts[alphabet_size]{};
    std::uint64_t right_counts[alphabet_size]{};
    for (std::size_t i = 0; i < left_length; ++i) {
        auto value = input[2 + i];
        if (value < 32 || value > 126) return invalid_result;
        if (value >= 65 && value <= 90) value += 32;
        ++left_counts[static_cast<std::size_t>(value - 32)];
    }
    for (std::size_t i = 0; i < right_length; ++i) {
        auto value = input[2 + left_length + i];
        if (value < 32 || value > 126) return invalid_result;
        if (value >= 65 && value <= 90) value += 32;
        ++right_counts[static_cast<std::size_t>(value - 32)];
    }

    double dot_product = 0.0, left_magnitude_squared = 0.0, right_magnitude_squared = 0.0;
    for (std::size_t i = 0; i < alphabet_size; ++i) {
        const double left = static_cast<double>(left_counts[i]);
        const double right = static_cast<double>(right_counts[i]);
        dot_product += left * right;
        left_magnitude_squared += left * left;
        right_magnitude_squared += right * right;
    }
    if (left_magnitude_squared <= 0.0 || right_magnitude_squared <= 0.0) return 0.0;
    return dot_product / (std::sqrt(left_magnitude_squared) * std::sqrt(right_magnitude_squared));
}
