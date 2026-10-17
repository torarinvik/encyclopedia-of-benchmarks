#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT (-1)
#define OUTPUT_ERROR (-2)
#define MAX_OUTPUT_BYTES 256

/* Volatile results preserve the source's per-operation binary64 rounding. */
static double rounded_multiply(double left, double right)
{
    volatile double result = left * right;
    return result;
}

static double rounded_add(double left, double right)
{
    volatile double result = left + right;
    return result;
}

static double rounded_subtract(double left, double right)
{
    volatile double result = left - right;
    return result;
}

static double rounded_divide(double left, double right)
{
    volatile double result = left / right;
    return result;
}

static double pixel_coordinate(double center, int64_t position,
                               int64_t dimension, double span)
{
    const double normalized = rounded_divide((double)position, (double)dimension);
    const double centered = rounded_subtract(normalized, 0.5);
    const double offset = rounded_multiply(centered, span);
    return rounded_add(center, offset);
}

int64_t mandelbrot(const int64_t *input, size_t input_length,
                   uint8_t *output, size_t output_capacity)
{
    if (input == NULL || input_length != 6) return INVALID_RESULT;

    const int64_t width = input[0];
    const int64_t height = input[1];
    const int64_t center_x_q = input[2];
    const int64_t center_y_q = input[3];
    const int64_t figure_width_q = input[4];
    const int64_t max_step = input[5];
    if (width < 1 || width > 16 || height < 1 || height > 16 ||
        center_x_q < -64 || center_x_q > 64 ||
        center_y_q < -64 || center_y_q > 64 ||
        figure_width_q < 1 || figure_width_q > 64 ||
        max_step < 2 || max_step > 64) return INVALID_RESULT;

    const double center_x = (double)center_x_q / 16.0;
    const double center_y = (double)center_y_q / 16.0;
    const double figure_width = (double)figure_width_q / 16.0;
    const double figure_height = rounded_multiply(
        rounded_divide(figure_width, (double)width), (double)height);
    uint8_t rendered[MAX_OUTPUT_BYTES];
    size_t output_index = 0;

    for (int64_t image_x = 0; image_x < width; ++image_x) {
        const double figure_x = pixel_coordinate(
            center_x, image_x, width, figure_width);
        for (int64_t image_y = 0; image_y < height; ++image_y) {
            const double figure_y = pixel_coordinate(
                center_y, image_y, height, figure_height);
            double a = figure_x;
            double b = figure_y;
            int64_t current_step = 0;
            for (int64_t step = 0; step < max_step; ++step) {
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
                (double)current_step, (double)(max_step - 1));
            rendered[output_index++] = distance >= 1.0 ? 0 : 255;
        }
    }

    if (output == NULL || output_capacity < output_index) return OUTPUT_ERROR;
    for (size_t index = 0; index < output_index; ++index)
        output[index] = rendered[index];
    return (int64_t)output_index;
}
