#include <cstddef>
#include <cstdint>

static double section_remainder_two(double section) {
    if (section < 2.0) return section;
    if (section < 4.0) return section - 2.0;
    if (section < 6.0) return section - 4.0;
    return section - 6.0;
}

static std::uint8_t round_channel(double channel) {
    return static_cast<std::uint8_t>(255.0 * channel + 0.5);
}

extern "C" std::int64_t hsv_to_rgb_conversion(const std::int64_t* input, std::size_t length,
                                               std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length != 3) return -1;
    if (input[0] < 0 || input[0] > 360000 || input[1] < 0 || input[1] > 255000000 ||
        input[2] < 0 || input[2] > 255000000) return -1;
    if (output == nullptr || capacity < 3) return -2;

    const double hue = static_cast<double>(input[0]) / 1000.0;
    const double saturation = static_cast<double>(input[1]) / 255000000.0;
    const double value = static_cast<double>(input[2]) / 255000000.0;
    const double chroma = value * saturation;
    const double hue_section = hue / 60.0;
    const double remainder = section_remainder_two(hue_section);
    const double delta = remainder - 1.0;
    const double absolute_delta = delta < 0.0 ? -delta : delta;
    const double second = chroma * (1.0 - absolute_delta);
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
    return 3;
}
