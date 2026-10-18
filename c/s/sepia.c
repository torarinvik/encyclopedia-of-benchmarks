/* Apply the pinned BGR sepia transform to a bounded packed image. */
#include <stddef.h>
#include <stdint.h>

#define MIN_DIMENSION 1
#define MAX_DIMENSION 8
#define MAX_FACTOR 255
#define MAX_PIXELS (MAX_DIMENSION * MAX_DIMENSION)
#define MAX_VALID_INPUT_LENGTH (3 + 3 * MAX_PIXELS)
#define MAX_PARSEABLE_INPUT_LENGTH (MAX_VALID_INPUT_LENGTH + 1)
#define MAX_OUTPUT_BYTES (3 * MAX_PIXELS)

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

static int allowed_channel(int64_t value)
{
    return value == 0 || value == 64 || value == 128 || value == 255;
}

int64_t sepia(const int64_t *input, size_t input_length,
              uint8_t *output, size_t output_capacity)
{
    if (input == NULL || input_length < 3 || input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    if (input[0] < MIN_DIMENSION || input[0] > MAX_DIMENSION ||
        input[1] < MIN_DIMENSION || input[1] > MAX_DIMENSION ||
        input[2] < 0 || input[2] > MAX_FACTOR) return -1;

    const size_t height = (size_t)input[0];
    const size_t width = (size_t)input[1];
    const int64_t factor = input[2];
    const size_t pixel_count = height * width;
    if (input_length != 3 + 3 * pixel_count || input_length > MAX_VALID_INPUT_LENGTH) return -1;
    for (size_t index = 0; index < 3 * pixel_count; ++index)
        if (!allowed_channel(input[3 + index])) return -1;

    uint8_t staged[MAX_OUTPUT_BYTES];
    for (size_t pixel = 0; pixel < pixel_count; ++pixel) {
        const double blue = (double)input[3 + 3 * pixel];
        const double green = (double)input[3 + 3 * pixel + 1];
        const double red = (double)input[3 + 3 * pixel + 2];
        const double red_term = rounded_multiply(0.2126, red);
        const double green_term = rounded_multiply(0.587, green);
        const double blue_term = rounded_multiply(0.114, blue);
        const double red_green_sum = rounded_add(red_term, green_term);
        const double grayscale = rounded_add(red_green_sum, blue_term);
        const int64_t gray = (int64_t)grayscale;
        const int64_t green_tinted = gray + factor;
        const int64_t red_tinted = gray + 2 * factor;
        staged[3 * pixel] = (uint8_t)gray;
        staged[3 * pixel + 1] = (uint8_t)(green_tinted < 255 ? green_tinted : 255);
        staged[3 * pixel + 2] = (uint8_t)(red_tinted < 255 ? red_tinted : 255);
    }

    const size_t output_bytes = 3 * pixel_count;
    if (output == NULL || output_capacity < output_bytes) return -2;
    for (size_t index = 0; index < output_bytes; ++index) output[index] = staged[index];
    return (int64_t)output_bytes;
}
