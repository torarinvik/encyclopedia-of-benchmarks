#include <cstddef>
#include <cstdint>

extern "C" std::int64_t k_means_clustering_c(const std::int64_t* input, std::size_t length) noexcept {
    constexpr std::size_t max_points = 8;
    constexpr std::size_t max_input_length = 18;
    constexpr std::size_t max_moves = 64;
    constexpr double center_scale = 256.0;
    constexpr std::int64_t center_bias = 4097;
    constexpr std::int64_t center_base = 8194;
    if (input == nullptr || length < 1 || length > max_input_length) return -1;
    const std::int64_t n_value = input[0];
    if (n_value < 3 || n_value > static_cast<std::int64_t>(max_points)) return -1;
    const std::size_t n = static_cast<std::size_t>(n_value);
    if (length != 1 + 2 * n) return -1;

    std::int64_t labels[max_points]{};
    bool has_zero = false;
    bool has_one = false;
    for (std::size_t index = 0; index < n; ++index) {
        const std::int64_t label = input[index + 1];
        const std::int64_t coordinate = input[1 + n + index];
        if (label != 0 && label != 1) return -1;
        labels[index] = label;
        has_zero = has_zero || label == 0;
        has_one = has_one || label == 1;
        if (coordinate < -16 || coordinate > 16 ||
            (index > 0 && input[n + index] >= coordinate)) return -1;
    }
    if (!has_zero || !has_one) return -1;

    for (std::size_t move = 0; move < max_moves; ++move) {
        double sums[2]{};
        std::size_t counts[2]{};
        for (std::size_t index = 0; index < n; ++index) {
            const std::size_t cluster = static_cast<std::size_t>(labels[index]);
            sums[cluster] += static_cast<double>(input[1 + n + index]);
            ++counts[cluster];
        }
        if (counts[0] == 0 || counts[1] == 0) return -1;
        const double centers[2] = {
            sums[0] / static_cast<double>(counts[0]),
            sums[1] / static_cast<double>(counts[1]),
        };

        std::size_t changed = 0;
        std::int64_t next_labels[max_points]{};
        for (std::size_t index = 0; index < n; ++index) {
            const double point = static_cast<double>(input[1 + n + index]);
            const double d0 = point - centers[0];
            const double d1 = point - centers[1];
            const std::size_t cluster = d1 * d1 < d0 * d0 ? 1 : 0;
            next_labels[index] = static_cast<std::int64_t>(cluster);
            if (next_labels[index] != labels[index]) ++changed;
        }
        for (std::size_t index = 0; index < n; ++index) labels[index] = next_labels[index];
        if (changed == 0) {
            const std::int64_t code0 = static_cast<std::int64_t>(centers[0] * center_scale) + center_bias;
            const std::int64_t code1 = static_cast<std::int64_t>(centers[1] * center_scale) + center_bias;
            if (code0 < 1 || code0 > 8193 || code1 < 1 || code1 > 8193) return -1;
            return code0 * center_base + code1;
        }
    }
    return -2;
}
