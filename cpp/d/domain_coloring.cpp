#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_output_bytes = 768;

std::int64_t phase_hue(std::int64_t real_part, std::int64_t imaginary_part) noexcept
{
    if (real_part == 0 && imaginary_part == 0) return 0;
    const std::int64_t abs_real = real_part < 0 ? -real_part : real_part;
    const std::int64_t abs_imaginary = imaginary_part < 0 ? -imaginary_part : imaginary_part;
    const std::int64_t high = abs_real > abs_imaginary ? abs_real : abs_imaginary;
    const std::int64_t low = abs_real < abs_imaginary ? abs_real : abs_imaginary;
    const std::int64_t step = 192 * low / high;
    std::int64_t hue;
    if (imaginary_part >= 0) {
        if (real_part >= 0) hue = abs_real >= abs_imaginary ? step : 384 - step;
        else hue = abs_real < abs_imaginary ? 384 + step : 768 - step;
    } else if (real_part < 0) {
        hue = abs_real >= abs_imaginary ? 768 + step : 1152 - step;
    } else {
        hue = abs_real < abs_imaginary ? 1152 + step : 1536 - step;
    }
    return hue == 1536 ? 0 : hue;
}

void store_pixel(std::array<std::uint8_t, max_output_bytes>& pixels,
                 std::size_t offset, std::int64_t hue,
                 std::int64_t magnitude_16) noexcept
{
    const std::int64_t value = 128 + 8 * (magnitude_16 % 16);
    const std::int64_t sector = hue / 256;
    const std::int64_t fraction = hue % 256;
    const auto rising = static_cast<std::uint8_t>(value * fraction / 255);
    const auto falling = static_cast<std::uint8_t>(value * (255 - fraction) / 255);
    const auto bright = static_cast<std::uint8_t>(value);
    std::uint8_t red = 0, green = 0, blue = 0;
    switch (sector) {
    case 0: red = bright; green = rising; break;
    case 1: red = falling; green = bright; break;
    case 2: green = bright; blue = rising; break;
    case 3: green = falling; blue = bright; break;
    case 4: red = rising; blue = bright; break;
    default: red = bright; blue = falling; break;
    }
    pixels[offset] = red;
    pixels[offset + 1] = green;
    pixels[offset + 2] = blue;
}
}

extern "C" std::int64_t domain_coloring(const std::int64_t *input,
                                         std::size_t input_length,
                                         std::uint8_t *output,
                                         std::size_t output_capacity) noexcept
{
    if (input == nullptr || input_length != 6) return -1;
    const auto width_value = input[0];
    const auto height_value = input[1];
    const auto x_start = input[2];
    const auto y_start = input[3];
    const auto x_step = input[4];
    const auto y_step = input[5];
    if (width_value < 1 || width_value > 16 || height_value < 1 || height_value > 16 ||
        x_start < -32 || x_start > 32 || y_start < -32 || y_start > 32 ||
        x_step < -8 || x_step > 8 || y_step < -8 || y_step > 8) return -1;
    const auto x_end = x_start + (width_value - 1) * x_step;
    const auto y_end = y_start + (height_value - 1) * y_step;
    if (x_end < -32 || x_end > 32 || y_end < -32 || y_end > 32) return -1;

    const auto width = static_cast<std::size_t>(width_value);
    const auto height = static_cast<std::size_t>(height_value);
    const auto byte_count = 3 * width * height;
    std::array<std::uint8_t, max_output_bytes> rendered{};
    std::size_t offset = 0;
    for (std::size_t row = 0; row < height; ++row) {
        const auto y_q = y_start + static_cast<std::int64_t>(row) * y_step;
        for (std::size_t column = 0; column < width; ++column) {
            const auto x_q = x_start + static_cast<std::int64_t>(column) * x_step;
            const auto x_squared = x_q * x_q;
            const auto y_squared = y_q * y_q;
            store_pixel(rendered, offset,
                       phase_hue(x_squared - y_squared, 2 * x_q * y_q),
                       x_squared + y_squared);
            offset += 3;
        }
    }
    if (output == nullptr || output_capacity < byte_count) return -2;
    for (std::size_t index = 0; index < byte_count; ++index) output[index] = rendered[index];
    return static_cast<std::int64_t>(byte_count);
}
