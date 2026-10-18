#include <math.h>
#include <stddef.h>
#include <stdint.h>
#include <string.h>

enum { MIN_SIDE = 3, MAX_SIDE = 16, MAX_VALID_INPUT_LENGTH = 257,
       MAX_PARSEABLE_INPUT_LENGTH = 258, MAX_OUTPUT_ELEMENTS = 512, MAX_OUTPUT_BYTES = 4096 };

static const int KERNEL_X[9] = {-1, 0, 1, -2, 0, 2, -1, 0, 1};
static const int KERNEL_Y[9] = {1, 2, 1, 0, 0, 0, -1, -2, -1};

static void write_f64_le(uint8_t *output, size_t offset, double value)
{
    uint64_t bits;
    memcpy(&bits, &value, sizeof(bits));
    for (unsigned int byte = 0; byte < 8u; ++byte) {
        output[offset + byte] = (uint8_t)(bits & UINT64_C(0xff));
        bits >>= 8u;
    }
}

int64_t sobel_filter(const int64_t *input, size_t input_length,
                     uint8_t *output, size_t capacity)
{
    if (input == NULL || input_length < 2u || input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    int64_t raw_side = input[0];
    if (raw_side < MIN_SIDE || raw_side > MAX_SIDE) return -1;
    size_t side = (size_t)raw_side;
    size_t pixel_count = side * side;
    if (input_length != pixel_count + 1u) return -1;
    int64_t image[MAX_SIDE * MAX_SIDE];
    for (size_t index = 0; index < pixel_count; ++index) {
        int64_t value = input[index + 1u];
        if (value < 0 || value > 255) return -1;
        image[index] = value;
    }

    int gradient_x[MAX_SIDE * MAX_SIDE];
    int gradient_y[MAX_SIDE * MAX_SIDE];
    int max_x = 0;
    int max_y = 0;
    for (size_t y = 0; y < side; ++y) {
        for (size_t x = 0; x < side; ++x) {
            int gx = 0;
            int gy = 0;
            for (int ky = 0; ky < 3; ++ky) {
                int sample_y = (int)y + ky - 1;
                if (sample_y < 0) sample_y = 0;
                if (sample_y >= (int)side) sample_y = (int)side - 1;
                for (int kx = 0; kx < 3; ++kx) {
                    int sample_x = (int)x + kx - 1;
                    if (sample_x < 0) sample_x = 0;
                    if (sample_x >= (int)side) sample_x = (int)side - 1;
                    int pixel = (int)image[(size_t)sample_y * side + (size_t)sample_x];
                    size_t kernel_index = (size_t)ky * 3u + (size_t)kx;
                    gx += pixel * KERNEL_X[kernel_index];
                    gy += pixel * KERNEL_Y[kernel_index];
                }
            }
            if (gx < 0) gx = -gx;
            if (gy < 0) gy = -gy;
            size_t index = y * side + x;
            gradient_x[index] = gx;
            gradient_y[index] = gy;
            if (gx > max_x) max_x = gx;
            if (gy > max_y) max_y = gy;
        }
    }
    if (max_x == 0 || max_y == 0) return -1;

    double scaled_x[MAX_SIDE * MAX_SIDE];
    double scaled_y[MAX_SIDE * MAX_SIDE];
    double magnitude[MAX_SIDE * MAX_SIDE];
    double theta[MAX_SIDE * MAX_SIDE];
    double max_magnitude = 0.0;
    for (size_t index = 0; index < pixel_count; ++index) {
        scaled_x[index] = ((double)gradient_x[index] * 255.0) / (double)max_x;
        scaled_y[index] = ((double)gradient_y[index] * 255.0) / (double)max_y;
        magnitude[index] = sqrt((scaled_x[index] * scaled_x[index]) +
                                (scaled_y[index] * scaled_y[index]));
        if (magnitude[index] > max_magnitude) max_magnitude = magnitude[index];
    }
    if (max_magnitude == 0.0) return -1;
    for (size_t index = 0; index < pixel_count; ++index) {
        double normalized = (magnitude[index] * 255.0) / max_magnitude;
        magnitude[index] = (double)(uint8_t)normalized;
        theta[index] = atan2(scaled_y[index], scaled_x[index]);
    }

    size_t output_elements = 2u * pixel_count;
    size_t output_bytes = output_elements * 8u;
    if (output_elements > MAX_OUTPUT_ELEMENTS || output_bytes > MAX_OUTPUT_BYTES) return -1;
    if (output == NULL || capacity < output_bytes) return -2;
    for (size_t index = 0; index < pixel_count; ++index) {
        write_f64_le(output, index * 8u, magnitude[index]);
        write_f64_le(output, (pixel_count + index) * 8u, theta[index]);
    }
    return (int64_t)output_elements;
}
