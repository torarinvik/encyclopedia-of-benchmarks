#include <cmath>
#include <cstddef>
#include <cstdint>
#include <cstring>

static constexpr double pi = 3.14159265358979323846264338327950288;

static void put_f32_le(std::uint8_t *output, std::size_t offset, double value) {
    const float rounded = static_cast<float>(value);
    std::uint32_t bits;
    std::memcpy(&bits, &rounded, sizeof(bits));
    for (std::size_t byte = 0; byte < 4; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}

extern "C" std::int64_t gabor_filter(const std::int64_t *values, std::size_t length,
                                      std::uint8_t *output, std::size_t capacity) {
    if (values == nullptr || length < 1 || length > 7) return -1;
    if (length != 6) return -1;
    const auto requested = values[0], sigma = values[1], theta = values[2];
    const auto wavelength = values[3], gamma = values[4], phase = values[5];
    if (requested < 1 || requested > 7 || sigma < 1 || sigma > 8 ||
        theta < 0 || theta > 359 || wavelength < 1 || wavelength > 8 ||
        gamma < 0 || gamma > 4 || phase < -6 || phase > 6) return -1;

    std::size_t side = static_cast<std::size_t>(requested);
    if (side % 2 == 0) ++side;
    const std::size_t output_bytes = side * side * 4;
    if (output == nullptr || capacity < output_bytes) return -2;

    const double angle = (static_cast<double>(theta) / 180.0) * pi;
    const double cosine = std::cos(angle), sine = std::sin(angle);
    const std::size_t center = side / 2;
    std::size_t offset = 0;
    for (std::size_t y = 0; y < side; ++y) {
        const double py = static_cast<double>(y) - static_cast<double>(center);
        for (std::size_t x = 0; x < side; ++x) {
            const double px = static_cast<double>(x) - static_cast<double>(center);
            const double kernel_x = cosine * px + sine * py;
            const double kernel_y = -sine * px + cosine * py;
            const double exponent = -(kernel_x * kernel_x +
                static_cast<double>(gamma * gamma) * kernel_y * kernel_y) /
                (2.0 * static_cast<double>(sigma) * static_cast<double>(sigma));
            const double phase_angle = 2.0 * pi * kernel_x /
                static_cast<double>(wavelength) + static_cast<double>(phase);
            put_f32_le(output, offset, std::exp(exponent) * std::cos(phase_angle));
            offset += 4;
        }
    }
    return static_cast<std::int64_t>(output_bytes);
}
