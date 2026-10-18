#include <cstddef>
#include <cstdint>

extern "C" std::int64_t kmeans_rust(const std::int64_t* input, std::size_t length) noexcept {
    constexpr std::size_t max_points = 8;
    constexpr std::size_t max_input_length = 10;
    constexpr std::size_t max_moves = 256;
    if (input == nullptr || length < 2 || length > max_input_length) return -1;
    const std::int64_t n_value = input[0];
    if (n_value < 2 || n_value > static_cast<std::int64_t>(max_points)) return -1;
    const std::size_t n = static_cast<std::size_t>(n_value);
    if (length != n + 1) return -1;

    double points[max_points]{};
    for (std::size_t index = 0; index < n; ++index) {
        const std::int64_t coordinate = input[index + 1];
        if (coordinate < -16 || coordinate > 16 || (index > 0 && input[index] >= coordinate)) return -1;
        points[index] = static_cast<double>(coordinate);
    }

    double centers[2] = {points[0], points[n / 2]};
    std::int64_t labels[max_points]{};
    for (std::size_t index = 0; index < n; ++index) {
        const double d0 = points[index] - centers[0];
        const double d1 = points[index] - centers[1];
        labels[index] = d1 * d1 < d0 * d0 ? 1 : 0;
    }

    for (std::size_t move = 0; move < max_moves; ++move) {
        double sums[2]{};
        std::size_t counts[2]{};
        for (std::size_t index = 0; index < n; ++index) {
            const std::size_t cluster = static_cast<std::size_t>(labels[index]);
            sums[cluster] += points[index];
            ++counts[cluster];
        }
        if (counts[0] == 0 || counts[1] == 0) return -1;
        centers[0] = sums[0] / static_cast<double>(counts[0]);
        centers[1] = sums[1] / static_cast<double>(counts[1]);

        std::int64_t next_labels[max_points]{};
        bool unchanged = true;
        for (std::size_t index = 0; index < n; ++index) {
            const double d0 = points[index] - centers[0];
            const double d1 = points[index] - centers[1];
            next_labels[index] = d1 * d1 < d0 * d0 ? 1 : 0;
            if (next_labels[index] != labels[index]) unchanged = false;
        }
        if (unchanged) {
            std::int64_t packed = 0;
            for (std::size_t index = 0; index < n; ++index)
                packed |= next_labels[index] << index;
            return packed;
        }
        for (std::size_t index = 0; index < n; ++index) labels[index] = next_labels[index];
    }
    return -2;
}
