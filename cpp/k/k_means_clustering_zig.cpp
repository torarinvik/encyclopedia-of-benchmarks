#include <cstddef>
#include <cstdint>

extern "C" std::int64_t k_means_clustering_zig(const std::int64_t* input,
                                                std::size_t length) noexcept {
    constexpr std::size_t max_input_length = 10;
    constexpr std::size_t max_points = 8;
    constexpr std::size_t max_moves = 64;
    constexpr std::int64_t center_bias = 4097;
    constexpr std::int64_t center_base = 8194;
    if (input == nullptr || length < 2 || length > max_input_length) return -1;
    if (input[0] < 2 || input[0] > static_cast<std::int64_t>(max_points)) return -1;
    const std::size_t point_count = static_cast<std::size_t>(input[0]);
    if (length != point_count + 1) return -1;

    float points[max_points]{};
    for (std::size_t index = 0; index < point_count; ++index) {
        const std::int64_t coordinate = input[index + 1];
        if (coordinate < -16 || coordinate > 16 || (index > 0 && input[index] >= coordinate)) return -1;
        points[index] = static_cast<float>(coordinate);
    }

    float centers[2] = {points[0], points[1]};
    std::size_t old_counts[2]{};
    for (std::size_t move = 0; move < max_moves; ++move) {
        float sums[2]{};
        std::size_t counts[2]{};
        for (std::size_t index = 0; index < point_count; ++index) {
            const float first_delta = points[index] - centers[0];
            const float second_delta = centers[1] - points[index];
            const float first_distance = first_delta * first_delta;
            const float second_distance = second_delta * second_delta;
            const std::size_t cluster = second_distance < first_distance ? 1 : 0;
            sums[cluster] = sums[cluster] + points[index];
            ++counts[cluster];
        }
        if (counts[0] == 0 || counts[1] == 0) return -1;
        const float moved[2] = {
            sums[0] / static_cast<float>(counts[0]),
            sums[1] / static_cast<float>(counts[1]),
        };
        if (moved[0] == centers[0] && moved[1] == centers[1] &&
            counts[0] == old_counts[0] && counts[1] == old_counts[1]) {
            const std::int64_t code0 = static_cast<std::int64_t>(moved[0] * 256.0f) + center_bias;
            const std::int64_t code1 = static_cast<std::int64_t>(moved[1] * 256.0f) + center_bias;
            if (code0 < 1 || code0 > 8193 || code1 < 1 || code1 > 8193) return -1;
            return (code0 * center_base + code1) * 81 +
                   static_cast<std::int64_t>(counts[0]) * 9 + static_cast<std::int64_t>(counts[1]);
        }
        centers[0] = moved[0];
        centers[1] = moved[1];
        old_counts[0] = counts[0];
        old_counts[1] = counts[1];
    }
    return -2;
}
