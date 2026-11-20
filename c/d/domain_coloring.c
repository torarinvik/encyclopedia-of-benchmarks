#include <stddef.h>
#include <stdint.h>

#define MAX_OUTPUT_BYTES 768

static int64_t dc_phase_hue(int64_t real_part, int64_t imaginary_part)
{
    if (real_part == 0 && imaginary_part == 0) return 0;
    const int64_t abs_real = real_part < 0 ? -real_part : real_part;
    const int64_t abs_imaginary = imaginary_part < 0 ? -imaginary_part : imaginary_part;
    const int64_t high = abs_real > abs_imaginary ? abs_real : abs_imaginary;
    const int64_t low = abs_real < abs_imaginary ? abs_real : abs_imaginary;
    const int64_t step = 192 * low / high;
    int64_t hue;

    if (imaginary_part >= 0) {
        if (real_part >= 0)
            hue = abs_real >= abs_imaginary ? step : 384 - step;
        else
            hue = abs_real < abs_imaginary ? 384 + step : 768 - step;
    } else if (real_part < 0) {
        hue = abs_real >= abs_imaginary ? 768 + step : 1152 - step;
    } else {
        hue = abs_real < abs_imaginary ? 1152 + step : 1536 - step;
    }
    return hue == 1536 ? 0 : hue;
}

static void dc_store_pixel(uint8_t *pixels, size_t offset, int64_t hue,
                           int64_t magnitude_16)
{
    const int64_t value = 128 + 8 * (magnitude_16 % 16);
    const int64_t sector = hue / 256;
    const int64_t fraction = hue % 256;
    const uint8_t rising = (uint8_t)(value * fraction / 255);
    const uint8_t falling = (uint8_t)(value * (255 - fraction) / 255);
    const uint8_t bright = (uint8_t)value;
    uint8_t red = 0, green = 0, blue = 0;

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

int64_t domain_coloring(const int64_t *input, size_t input_length,
                        uint8_t *output, size_t output_capacity)
{
    if (input == NULL || input_length != 6) return -1;
    const int64_t width_value = input[0];
    const int64_t height_value = input[1];
    const int64_t x_start = input[2];
    const int64_t y_start = input[3];
    const int64_t x_step = input[4];
    const int64_t y_step = input[5];
    if (width_value < 1 || width_value > 16 || height_value < 1 || height_value > 16 ||
        x_start < -32 || x_start > 32 || y_start < -32 || y_start > 32 ||
        x_step < -8 || x_step > 8 || y_step < -8 || y_step > 8) return -1;
    const int64_t x_end = x_start + (width_value - 1) * x_step;
    const int64_t y_end = y_start + (height_value - 1) * y_step;
    if (x_end < -32 || x_end > 32 || y_end < -32 || y_end > 32) return -1;

    const size_t width = (size_t)width_value;
    const size_t height = (size_t)height_value;
    const size_t pixels = width * height;
    const size_t byte_count = 3 * pixels;
    uint8_t rendered[MAX_OUTPUT_BYTES];
    size_t offset = 0;
    for (size_t row = 0; row < height; ++row) {
        const int64_t y_q = y_start + (int64_t)row * y_step;
        for (size_t column = 0; column < width; ++column) {
            const int64_t x_q = x_start + (int64_t)column * x_step;
            const int64_t x_squared = x_q * x_q;
            const int64_t y_squared = y_q * y_q;
            const int64_t real_part = x_squared - y_squared;
            const int64_t imaginary_part = 2 * x_q * y_q;
            const int64_t magnitude_16 = x_squared + y_squared;
            dc_store_pixel(rendered, offset,
                           dc_phase_hue(real_part, imaginary_part), magnitude_16);
            offset += 3;
        }
    }
    if (output == NULL || output_capacity < byte_count) return -2;
    for (size_t index = 0; index < byte_count; ++index) output[index] = rendered[index];
    return (int64_t)byte_count;
}
