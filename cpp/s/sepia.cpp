/* Apply the pinned BGR sepia transform to a bounded packed image. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t min_dimension = 1;
constexpr std::size_t max_dimension = 8;
constexpr std::int64_t max_factor = 255;
constexpr std::size_t max_pixels = max_dimension * max_dimension;
constexpr std::size_t max_valid_input_length = 3 + 3 * max_pixels;
constexpr std::size_t max_parseable_input_length = max_valid_input_length + 1;
constexpr std::size_t max_output_bytes = 3 * max_pixels;

double rounded_multiply(double left, double right) noexcept {
    volatile double result = left * right;
    return result;
}

double rounded_add(double left, double right) noexcept {
    volatile double result = left + right;
    return result;
}

bool allowed_channel(std::int64_t value) noexcept {
    return value == 0 || value == 64 || value == 128 || value == 255;
}
}

extern "C" std::int64_t sepia(const std::int64_t* input, std::size_t input_length,
                               std::uint8_t* output, std::size_t output_capacity) noexcept {
    if (input == nullptr || input_length < 3 || input_length > max_parseable_input_length) return -1;
    if (input[0] < static_cast<std::int64_t>(min_dimension) ||
        input[0] > static_cast<std::int64_t>(max_dimension) ||
        input[1] < static_cast<std::int64_t>(min_dimension) ||
        input[1] > static_cast<std::int64_t>(max_dimension) ||
        input[2] < 0 || input[2] > max_factor) return -1;

    const auto height = static_cast<std::size_t>(input[0]);
    const auto width = static_cast<std::size_t>(input[1]);
    const auto factor = input[2];
    const std::size_t pixel_count = height * width;
    if (input_length != 3 + 3 * pixel_count || input_length > max_valid_input_length) return -1;
    for (std::size_t index = 0; index < 3 * pixel_count; ++index)
        if (!allowed_channel(input[3 + index])) return -1;

    std::uint8_t staged[max_output_bytes]{};
    for (std::size_t pixel = 0; pixel < pixel_count; ++pixel) {
        const double blue = static_cast<double>(input[3 + 3 * pixel]);
        const double green = static_cast<double>(input[3 + 3 * pixel + 1]);
        const double red = static_cast<double>(input[3 + 3 * pixel + 2]);
        const double red_term = rounded_multiply(0.2126, red);
        const double green_term = rounded_multiply(0.587, green);
        const double blue_term = rounded_multiply(0.114, blue);
        const double red_green_sum = rounded_add(red_term, green_term);
        const double grayscale = rounded_add(red_green_sum, blue_term);
        const auto gray = static_cast<std::int64_t>(grayscale);
        const auto green_tinted = gray + factor;
        const auto red_tinted = gray + 2 * factor;
        staged[3 * pixel] = static_cast<std::uint8_t>(gray);
        staged[3 * pixel + 1] = static_cast<std::uint8_t>(green_tinted < 255 ? green_tinted : 255);
        staged[3 * pixel + 2] = static_cast<std::uint8_t>(red_tinted < 255 ? red_tinted : 255);
    }

    const std::size_t output_bytes = 3 * pixel_count;
    if (output == nullptr || output_capacity < output_bytes) return -2;
    for (std::size_t index = 0; index < output_bytes; ++index) output[index] = staged[index];
    return static_cast<std::int64_t>(output_bytes);
}
