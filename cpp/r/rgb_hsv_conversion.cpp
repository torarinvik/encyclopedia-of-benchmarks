#include <cstddef>
#include <cstdint>
#include <algorithm>
#include <cstring>

static void write_f64_le(std::uint8_t* output, std::size_t offset, double value) {
    std::uint64_t bits;
    std::memcpy(&bits, &value, sizeof(bits));
    for (std::size_t i = 0; i < 8; ++i) output[offset + i] = static_cast<std::uint8_t>(bits >> (8 * i));
}

extern "C" std::int64_t rgb_hsv_conversion(const std::int64_t* input, std::size_t length,
                                           std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length != 3) return -1;
    for (std::size_t i = 0; i < 3; ++i) if (input[i] < 0 || input[i] > 255) return -1;
    if (output == nullptr || capacity < 24) return -2;
    const double red = static_cast<double>(input[0]) / 255.0;
    const double green = static_cast<double>(input[1]) / 255.0;
    const double blue = static_cast<double>(input[2]) / 255.0;
    const double value = std::max(std::max(red, green), blue);
    const double chroma = value - std::min(std::min(red, green), blue);
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
    return 24;
}
