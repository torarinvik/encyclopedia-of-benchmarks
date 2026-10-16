#include <stddef.h>
#include <stdint.h>

#define OUTPUT_BYTES 3
#define MAX_COMPONENT_SCALED INT64_C(255000000)

static double section_remainder_two(double section) {
    if (section < 2.0) return section;
    if (section < 4.0) return section - 2.0;
    if (section < 6.0) return section - 4.0;
    return section - 6.0;
}

static uint8_t round_channel(double channel) {
    return (uint8_t)(255.0 * channel + 0.5);
}

int64_t hsv_to_rgb_conversion(const int64_t *input, size_t length,
                              uint8_t *output, size_t capacity) {
    if (input == NULL || length != 3) return -1;
    if (input[0] < 0 || input[0] > 360000 ||
        input[1] < 0 || input[1] > MAX_COMPONENT_SCALED ||
        input[2] < 0 || input[2] > MAX_COMPONENT_SCALED) return -1;
    if (output == NULL || capacity < OUTPUT_BYTES) return -2;

    const double hue = (double)input[0] / 1000.0;
    const double saturation = (double)input[1] / (double)MAX_COMPONENT_SCALED;
    const double value = (double)input[2] / (double)MAX_COMPONENT_SCALED;
    const double chroma = value * saturation;
    const double hue_section = hue / 60.0;
    const double second = chroma * (1.0 - (section_remainder_two(hue_section) - 1.0 < 0.0
        ? -(section_remainder_two(hue_section) - 1.0)
        : section_remainder_two(hue_section) - 1.0));
    const double match = value - chroma;
    double red, green, blue;
    if (hue_section >= 0.0 && hue_section <= 1.0) {
        red = chroma + match; green = second + match; blue = match;
    } else if (hue_section > 1.0 && hue_section <= 2.0) {
        red = second + match; green = chroma + match; blue = match;
    } else if (hue_section > 2.0 && hue_section <= 3.0) {
        red = match; green = chroma + match; blue = second + match;
    } else if (hue_section > 3.0 && hue_section <= 4.0) {
        red = match; green = second + match; blue = chroma + match;
    } else if (hue_section > 4.0 && hue_section <= 5.0) {
        red = second + match; green = match; blue = chroma + match;
    } else {
        red = chroma + match; green = match; blue = second + match;
    }
    output[0] = round_channel(red);
    output[1] = round_channel(green);
    output[2] = round_channel(blue);
    return OUTPUT_BYTES;
}
