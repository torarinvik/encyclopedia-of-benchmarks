#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t min_points = 3;
constexpr std::size_t max_points = 8;
constexpr std::size_t max_parseable_input_length = 10;
constexpr std::size_t max_moves = 64;
constexpr std::int64_t center_scale = 256;
constexpr std::int64_t center_bias = 4097;
constexpr std::int64_t center_base = 8194;
}

extern "C" std::int64_t k_means_julia(const std::int64_t* input, std::size_t length) noexcept {
    if (input == nullptr || length < 2 || length > max_parseable_input_length) return -1;
    if (input[0] < static_cast<std::int64_t>(min_points) || input[0] > static_cast<std::int64_t>(max_points)) return -1;
    const auto point_count = static_cast<std::size_t>(input[0]);
    if (length != point_count + 1) return -1;

    double points[max_points];
    for (std::size_t index = 0; index < point_count; ++index) {
        const auto value = input[index + 1];
        if (value < -16 || value > 16 || (index > 0 && input[index] >= value)) return -1;
        points[index] = static_cast<double>(value);
    }

    double centers[2] = {points[0], points[point_count / 2]};
    for (std::size_t move = 0; move < max_moves; ++move) {
        double sums[2] = {0.0, 0.0};
        std::size_t counts[2] = {0, 0};
        for (std::size_t index = 0; index < point_count; ++index) {
            const double first_delta = points[index] - centers[0];
            const double second_delta = points[index] - centers[1];
            const double first_distance = std::sqrt(first_delta * first_delta);
            const double second_distance = std::sqrt(second_delta * second_delta);
            const std::size_t cluster = second_distance < first_distance ? 1 : 0;
            sums[cluster] += points[index];
            counts[cluster] += 1;
        }
        if (counts[0] == 0 || counts[1] == 0) return -1;
        const double moved[2] = {
            sums[0] / static_cast<double>(counts[0]),
            sums[1] / static_cast<double>(counts[1]),
        };
        if (moved[0] == centers[0] && moved[1] == centers[1]) {
            const auto quantized_first = static_cast<std::int64_t>(moved[0] * static_cast<double>(center_scale));
            const auto quantized_second = static_cast<std::int64_t>(moved[1] * static_cast<double>(center_scale));
            const auto code_first = quantized_first + center_bias;
            const auto code_second = quantized_second + center_bias;
            if (code_first < 1 || code_first > 8193 || code_second < 1 || code_second > 8193) return -1;
            return code_first * center_base + code_second;
        }
        centers[0] = moved[0];
        centers[1] = moved[1];
    }
    return -2;
}
