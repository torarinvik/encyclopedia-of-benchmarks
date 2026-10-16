// Portable byte-channel brightness and contrast transforms.
#include <cstddef>
#include <cstdint>

namespace {
std::int64_t truncate_divide(std::int64_t numerator, std::int64_t denominator) {
    return numerator < 0 ? -((-numerator) / denominator) : numerator / denominator;
}
std::int64_t transform_channel(std::int64_t channel, std::int64_t level, std::int64_t mode) {
    std::int64_t value;
    if (mode == 0) value = channel + level;
    else {
        const std::int64_t denominator = 255 * (259 - level);
        const std::int64_t numerator = 128 * denominator + 259 * (level + 255) * (channel - 128);
        value = truncate_divide(numerator, denominator);
    }
    if (value < 0) return 0;
    if (value > 255) return 255;
    return value;
}
std::int64_t image_point_transform(const std::int64_t *values, std::size_t length,
                                   std::uint8_t *output, std::size_t output_capacity,
                                   std::int64_t mode) {
    if (values == nullptr || length < 1 || length > 4096) return -1;
    const std::int64_t level = values[0];
    if (level < -255 || level > 255) return -1;
    const std::size_t channels = length - 1;
    for (std::size_t index = 0; index < channels; ++index)
        if (values[index + 1] < 0 || values[index + 1] > 255) return -1;
    if (channels > output_capacity || (channels != 0 && output == nullptr)) return -2;
    for (std::size_t index = 0; index < channels; ++index)
        output[index] = static_cast<std::uint8_t>(transform_channel(values[index + 1], level, mode));
    return static_cast<std::int64_t>(channels);
}
}
extern "C" std::int64_t change_brightness(const std::int64_t *values, std::size_t length,
    std::uint8_t *output, std::size_t output_capacity) noexcept {
    return image_point_transform(values, length, output, output_capacity, 0);
}
extern "C" std::int64_t change_contrast(const std::int64_t *values, std::size_t length,
    std::uint8_t *output, std::size_t output_capacity) noexcept {
    return image_point_transform(values, length, output, output_capacity, 1);
}
