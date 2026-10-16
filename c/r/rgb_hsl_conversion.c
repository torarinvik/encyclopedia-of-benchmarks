#include <stddef.h>
#include <stdint.h>

#define INPUT_COUNT 3
#define OUTPUT_COUNT 4

int64_t rgb_hsl_conversion(const int64_t *input, size_t length,
                           uint8_t *output, size_t capacity) {
    if (input == NULL || length != INPUT_COUNT) return -1;
    for (size_t i = 0; i < INPUT_COUNT; ++i)
        if (input[i] < 0 || input[i] > 255) return -1;
    if (output == NULL || capacity < OUTPUT_COUNT) return -2;

    const double red = (double)input[0] / 255.0;
    const double green = (double)input[1] / 255.0;
    const double blue = (double)input[2] / 255.0;
    double minimum = red, maximum = red;
    if (green < minimum) minimum = green;
    if (blue < minimum) minimum = blue;
    if (green > maximum) maximum = green;
    if (blue > maximum) maximum = blue;

    int channel = 0;
    if (maximum == green) channel = 1;
    else if (maximum == blue) channel = 2;
    const double luminance = (minimum + maximum) / 2.0;
    double saturation = 0.0;
    if (minimum != maximum) {
        if (luminance <= 0.5) saturation = (maximum - minimum) / (maximum + minimum);
        else saturation = (maximum - minimum) / (2.0 - maximum - minimum);
    }
    double hue = 0.0;
    if (saturation != 0.0) {
        if (channel == 0) hue = (green - blue) / (maximum - minimum);
        else if (channel == 1) hue = 2.0 + (blue - red) / (maximum - minimum);
        else hue = 4.0 + (red - green) / (maximum - minimum);
    }
    hue *= 60.0;
    if (hue < 0.0) hue += 360.0;
    const uint16_t h = (uint16_t)(hue + 0.5);
    const uint8_t s = (uint8_t)(saturation * 100.0 + 0.5);
    const uint8_t l = (uint8_t)(luminance * 100.0 + 0.5);
    output[0] = (uint8_t)(h & 255);
    output[1] = (uint8_t)(h >> 8);
    output[2] = s;
    output[3] = l;
    return OUTPUT_COUNT;
}
