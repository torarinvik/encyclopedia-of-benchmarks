#include <stddef.h>
#include <stdint.h>
#include <string.h>

#define OUTPUT_COUNT 24

static void write_f64_le(uint8_t *output, size_t offset, double value) {
    uint64_t bits;
    memcpy(&bits, &value, sizeof(bits));
    for (size_t i = 0; i < 8; ++i) output[offset + i] = (uint8_t)(bits >> (8 * i));
}

int64_t rgb_hsv_conversion(const int64_t *input, size_t length,
                           uint8_t *output, size_t capacity) {
    if (input == NULL || length != 3) return -1;
    for (size_t i = 0; i < 3; ++i) if (input[i] < 0 || input[i] > 255) return -1;
    if (output == NULL || capacity < OUTPUT_COUNT) return -2;
    const double red = (double)input[0] / 255.0;
    const double green = (double)input[1] / 255.0;
    const double blue = (double)input[2] / 255.0;
    const double value = (red > green ? red : green) > blue ? (red > green ? red : green) : blue;
    const double minimum = (red < green ? red : green) < blue ? (red < green ? red : green) : blue;
    const double chroma = value - minimum;
    const double saturation = value == 0.0 ? 0.0 : chroma / value;
    double hue;
    if (chroma == 0.0) hue = 0.0;
    else if (value == red) hue = 60.0 * (0.0 + (green - blue) / chroma);
    else if (value == green) hue = 60.0 * (2.0 + (blue - red) / chroma);
    else hue = 60.0 * (4.0 + (red - green) / chroma);
    hue += 360.0;
    if (hue >= 360.0) hue -= 360.0;
    write_f64_le(output, 0, hue);
    write_f64_le(output, 8, saturation);
    write_f64_le(output, 16, value);
    return OUTPUT_COUNT;
}
