/* Portable byte-channel brightness and contrast transforms. */
#include <stddef.h>
#include <stdint.h>

static int64_t truncate_divide(int64_t numerator, int64_t denominator)
{
    return numerator < 0 ? -((-numerator) / denominator) : numerator / denominator;
}

static int64_t transform_channel(int64_t channel, int64_t level, int64_t mode)
{
    int64_t value;
    if (mode == 0) {
        value = channel + level;
    } else {
        const int64_t denominator = 255 * (259 - level);
        const int64_t numerator = 128 * denominator + 259 * (level + 255) * (channel - 128);
        value = truncate_divide(numerator, denominator);
    }
    if (value < 0) return 0;
    if (value > 255) return 255;
    return value;
}

static int64_t image_point_transform(const int64_t *values, size_t length,
                                     uint8_t *output, size_t output_capacity,
                                     int64_t mode)
{
    if (values == NULL || length < 1 || length > 4096) return -1;
    const int64_t level = values[0];
    if (level < -255 || level > 255) return -1;
    const size_t channels = length - 1;
    for (size_t index = 0; index < channels; ++index)
        if (values[index + 1] < 0 || values[index + 1] > 255) return -1;
    if (channels > output_capacity || (channels != 0 && output == NULL)) return -2;
    for (size_t index = 0; index < channels; ++index)
        output[index] = (uint8_t)transform_channel(values[index + 1], level, mode);
    return (int64_t)channels;
}

int64_t change_brightness(const int64_t *values, size_t length, uint8_t *output, size_t output_capacity)
{ return image_point_transform(values, length, output, output_capacity, 0); }
int64_t change_contrast(const int64_t *values, size_t length, uint8_t *output, size_t output_capacity)
{ return image_point_transform(values, length, output, output_capacity, 1); }
