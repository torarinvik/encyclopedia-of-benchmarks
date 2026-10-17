#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t invalid_result = -1;
constexpr std::int64_t output_error = -2;
constexpr std::size_t max_output_bytes = 256;

double rounded_multiply(double left, double right) noexcept
{
    volatile double result = left * right;
    return result;
}

double rounded_add(double left, double right) noexcept
{
    volatile double result = left + right;
    return result;
}

double rounded_subtract(double left, double right) noexcept
{
    volatile double result = left - right;
    return result;
}

double rounded_divide(double left, double right) noexcept
{
    volatile double result = left / right;
    return result;
}

double pixel_coordinate(double center, std::int64_t position,
                        std::int64_t dimension, double span) noexcept
{
    const double normalized = rounded_divide(
        static_cast<double>(position), static_cast<double>(dimension));
    const double centered = rounded_subtract(normalized, 0.5);
    const double offset = rounded_multiply(centered, span);
    return rounded_add(center, offset);
}
}

extern "C" std::int64_t mandelbrot(const std::int64_t *input,
                                    std::size_t input_length,
                                    std::uint8_t *output,
                                    std::size_t output_capacity) noexcept
{
    if (input == nullptr || input_length != 6) return invalid_result;

    const std::int64_t width = input[0];
    const std::int64_t height = input[1];
    const std::int64_t center_x_q = input[2];
    const std::int64_t center_y_q = input[3];
    const std::int64_t figure_width_q = input[4];
    const std::int64_t max_step = input[5];
    if (width < 1 || width > 16 || height < 1 || height > 16 ||
        center_x_q < -64 || center_x_q > 64 ||
        center_y_q < -64 || center_y_q > 64 ||
        figure_width_q < 1 || figure_width_q > 64 ||
        max_step < 2 || max_step > 64) return invalid_result;

    const double center_x = static_cast<double>(center_x_q) / 16.0;
    const double center_y = static_cast<double>(center_y_q) / 16.0;
    const double figure_width = static_cast<double>(figure_width_q) / 16.0;
    const double figure_height = rounded_multiply(
        rounded_divide(figure_width, static_cast<double>(width)),
        static_cast<double>(height));
    std::array<std::uint8_t, max_output_bytes> rendered{};
    std::size_t output_index = 0;

    for (std::int64_t image_x = 0; image_x < width; ++image_x) {
        const double figure_x = pixel_coordinate(
            center_x, image_x, width, figure_width);
        for (std::int64_t image_y = 0; image_y < height; ++image_y) {
            const double figure_y = pixel_coordinate(
                center_y, image_y, height, figure_height);
            double a = figure_x;
            double b = figure_y;
            std::int64_t current_step = 0;
            for (std::int64_t step = 0; step < max_step; ++step) {
                current_step = step;
                const double a_squared = rounded_multiply(a, a);
                const double b_squared = rounded_multiply(b, b);
                const double difference = rounded_subtract(a_squared, b_squared);
                const double a_new = rounded_add(difference, figure_x);
                const double twice_a = rounded_multiply(2.0, a);
                const double twice_a_times_b = rounded_multiply(twice_a, b);
                const double b_new = rounded_add(twice_a_times_b, figure_y);
                a = a_new;
                b = b_new;

                const double next_a_squared = rounded_multiply(a, a);
                const double next_b_squared = rounded_multiply(b, b);
                const double magnitude_squared = rounded_add(
                    next_a_squared, next_b_squared);
                if (magnitude_squared > 4.0) break;
            }
            const double distance = rounded_divide(
                static_cast<double>(current_step), static_cast<double>(max_step - 1));
            rendered[output_index++] = distance >= 1.0 ? 0 : 255;
        }
    }

    if (output == nullptr || output_capacity < output_index) return output_error;
    for (std::size_t index = 0; index < output_index; ++index)
        output[index] = rendered[index];
    return static_cast<std::int64_t>(output_index);
}
