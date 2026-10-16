#include <cstddef>
#include <cstdint>
#include <cmath>

namespace {
constexpr std::size_t MAX_SIDE = 32;
constexpr std::size_t MAX_PIXELS = MAX_SIDE * MAX_SIDE;

void write_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) noexcept {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t bilateral_filter(const std::int64_t *values, std::size_t length,
                                           std::uint8_t *output, std::size_t output_capacity) noexcept {
    if (values == nullptr || length < 5 || length > 5 + MAX_PIXELS) return -1;
    const auto height_value = values[0], width_value = values[1], kernel_value = values[2];
    const auto spatial_q = values[3], intensity_q = values[4];
    if (height_value < 1 || height_value > static_cast<std::int64_t>(MAX_SIDE) ||
        width_value < 1 || width_value > static_cast<std::int64_t>(MAX_SIDE) ||
        (kernel_value != 1 && kernel_value != 3 && kernel_value != 5 && kernel_value != 7) ||
        spatial_q < 1 || spatial_q > 1000000 || intensity_q < 1 || intensity_q > 1000000) return -1;
    const auto height = static_cast<std::size_t>(height_value), width = static_cast<std::size_t>(width_value);
    const auto pixels = height * width;
    if (length != 5 + pixels) return -1;
    for (std::size_t index = 0; index < pixels; ++index)
        if (values[5 + index] < 0 || values[5 + index] > 1000000) return -1;
    const auto required = pixels * 8;
    if (output == nullptr || output_capacity < required) return -2;

    const auto kernel_size = static_cast<std::size_t>(kernel_value);
    const auto radius = kernel_size / 2;
    const auto row_end = height >= kernel_size ? height - radius : radius;
    const auto column_end = width >= kernel_size ? width - radius : radius;
    const double spatial_variance = static_cast<double>(spatial_q) / 1000000.0;
    const double intensity_variance = static_cast<double>(intensity_q) / 1000000.0;
    std::int64_t filtered[MAX_PIXELS]{};
    for (std::size_t row = radius; row < row_end; ++row) {
        for (std::size_t column = radius; column < column_end; ++column) {
            const double center = static_cast<double>(values[5 + row * width + column]) / 1000000.0;
            double weighted_sum = 0.0, weight_sum = 0.0;
            for (int dy = -static_cast<int>(radius); dy <= static_cast<int>(radius); ++dy) {
                for (int dx = -static_cast<int>(radius); dx <= static_cast<int>(radius); ++dx) {
                    const auto sample_index = static_cast<std::size_t>(static_cast<int>(row) + dy) * width +
                                              static_cast<std::size_t>(static_cast<int>(column) + dx);
                    const double sample = static_cast<double>(values[5 + sample_index]) / 1000000.0;
                    const double spatial_distance_squared = static_cast<double>(dx * dx + dy * dy);
                    const double difference = sample - center;
                    double weight = std::exp(-spatial_distance_squared / (2.0 * spatial_variance));
                    weight *= std::exp(-(difference * difference) / (2.0 * intensity_variance));
                    weighted_sum += sample * weight;
                    weight_sum += weight;
                }
            }
            filtered[row * width + column] = static_cast<std::int64_t>(weighted_sum / weight_sum * 1000000.0 + 0.5);
        }
    }
    for (std::size_t index = 0; index < pixels; ++index) write_i64_le(output, index * 8, filtered[index]);
    return static_cast<std::int64_t>(required);
}
