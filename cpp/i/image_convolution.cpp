#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_side = 16;
constexpr std::size_t max_kernel_side = 7;

void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    const std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
}
}

extern "C" std::int64_t image_convolution(const std::int64_t *values, std::size_t length,
                                            std::uint8_t *output, std::size_t output_capacity) {
    if (values == nullptr || length < 3 || length > 308) return -1;
    const std::int64_t side_value = values[0];
    const std::int64_t kernel_side_value = values[1];
    if (side_value < 1 || side_value > static_cast<std::int64_t>(max_side) ||
        kernel_side_value < 1 || kernel_side_value > static_cast<std::int64_t>(max_kernel_side) ||
        kernel_side_value % 2 == 0) return -1;
    const std::size_t side = static_cast<std::size_t>(side_value);
    const std::size_t kernel_side = static_cast<std::size_t>(kernel_side_value);
    const std::size_t pixel_count = side * side;
    const std::size_t kernel_count = kernel_side * kernel_side;
    if (length != 2 + pixel_count + kernel_count) return -1;
    for (std::size_t index = 0; index < pixel_count; ++index)
        if (values[2 + index] < 0 || values[2 + index] > 255) return -1;
    for (std::size_t index = 0; index < kernel_count; ++index)
        if (values[2 + pixel_count + index] < -16 || values[2 + pixel_count + index] > 16) return -1;
    const std::size_t output_bytes = pixel_count * 8;
    if (output == nullptr || output_capacity < output_bytes) return -2;

    const std::int64_t radius = static_cast<std::int64_t>(kernel_side / 2);
    for (std::size_t row = 0; row < side; ++row) {
        for (std::size_t column = 0; column < side; ++column) {
            std::int64_t total = 0;
            for (std::size_t kernel_row = 0; kernel_row < kernel_side; ++kernel_row) {
                std::int64_t source_row = static_cast<std::int64_t>(row) + static_cast<std::int64_t>(kernel_row) - radius;
                if (source_row < 0) source_row = 0;
                if (source_row >= static_cast<std::int64_t>(side)) source_row = static_cast<std::int64_t>(side) - 1;
                for (std::size_t kernel_column = 0; kernel_column < kernel_side; ++kernel_column) {
                    std::int64_t source_column = static_cast<std::int64_t>(column) + static_cast<std::int64_t>(kernel_column) - radius;
                    if (source_column < 0) source_column = 0;
                    if (source_column >= static_cast<std::int64_t>(side)) source_column = static_cast<std::int64_t>(side) - 1;
                    const std::int64_t pixel = values[2 + static_cast<std::size_t>(source_row) * side + static_cast<std::size_t>(source_column)];
                    const std::int64_t weight = values[2 + pixel_count + kernel_row * kernel_side + kernel_column];
                    total += pixel * weight;
                }
            }
            store_i64_le(output, (row * side + column) * 8, total);
        }
    }
    return static_cast<std::int64_t>(output_bytes);
}
