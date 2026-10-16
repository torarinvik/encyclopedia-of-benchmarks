// Flip bounded grayscale images and normalized box centers portably.
#include <cstddef>
#include <cstdint>

namespace { constexpr std::size_t max_width = 16, max_height = 16, max_boxes = 16; }

static void store_i32_le(std::uint8_t *output, std::size_t position, std::int32_t value)
{
    const auto bits = static_cast<std::uint32_t>(value);
    for (std::size_t byte = 0; byte < 4; ++byte)
        output[position + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
}

extern "C" std::int64_t flip_augmentation(const std::int64_t *values, std::size_t length,
                                           std::uint8_t *output, std::size_t output_capacity) noexcept
{
    if (values == nullptr || length < 4 || length > 340) return -1;
    if (values[0] < 1 || values[0] > static_cast<std::int64_t>(max_width) ||
        values[1] < 1 || values[1] > static_cast<std::int64_t>(max_height) ||
        (values[2] != 0 && values[2] != 1) || values[3] < 0 ||
        values[3] > static_cast<std::int64_t>(max_boxes)) return -1;
    const auto width = static_cast<std::size_t>(values[0]);
    const auto height = static_cast<std::size_t>(values[1]);
    const auto flip_type = static_cast<std::size_t>(values[2]);
    const auto box_count = static_cast<std::size_t>(values[3]);
    const std::size_t pixel_count = width * height;
    if (length != 4 + pixel_count + 5 * box_count) return -1;
    for (std::size_t index = 0; index < pixel_count; ++index)
        if (values[4 + index] < 0 || values[4 + index] > 255) return -1;
    for (std::size_t box = 0; box < box_count; ++box) {
        const auto base = 4 + pixel_count + 5 * box;
        if (values[base] < 0 || values[base] > INT32_MAX) return -1;
        for (std::size_t field = 1; field < 5; ++field)
            if (values[base + field] < 0 || values[base + field] > 1000000) return -1;
    }
    const std::size_t output_bytes = pixel_count + 20 * box_count;
    if (output == nullptr || output_capacity < output_bytes) return -2;

    for (std::size_t row = 0; row < height; ++row) {
        for (std::size_t column = 0; column < width; ++column) {
            const auto source_row = flip_type == 0 ? height - 1 - row : row;
            const auto source_column = flip_type == 1 ? width - 1 - column : column;
            output[row * width + column] = static_cast<std::uint8_t>(values[4 + source_row * width + source_column]);
        }
    }
    for (std::size_t box = 0; box < box_count; ++box) {
        const auto base = 4 + pixel_count + 5 * box;
        const auto output_base = pixel_count + 20 * box;
        for (std::size_t field = 0; field < 5; ++field) {
            auto value = values[base + field];
            if (flip_type == 1 && field == 1) value = 1000000 - value;
            if (flip_type == 0 && field == 2) value = 1000000 - value;
            store_i32_le(output, output_base + 4 * field, static_cast<std::int32_t>(value));
        }
    }
    return static_cast<std::int64_t>(output_bytes);
}
