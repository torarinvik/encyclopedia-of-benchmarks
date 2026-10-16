#include <math.h>
#include <stddef.h>
#include <stdint.h>
#include <string.h>

#define MAX_OUTPUT_BYTES 196
#define PI 3.14159265358979323846264338327950288

static void put_f32_le(uint8_t *output, size_t offset, double value) {
    float rounded = (float)value;
    uint32_t bits;
    memcpy(&bits, &rounded, sizeof(bits));
    for (size_t byte = 0; byte < 4; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t gabor_filter(const int64_t *values, size_t length,
                     uint8_t *output, size_t capacity) {
    if (values == NULL || length < 1 || length > 7) return -1;
    if (length != 6) return -1;
    const int64_t requested = values[0], sigma = values[1], theta = values[2];
    const int64_t wavelength = values[3], gamma = values[4], phase = values[5];
    if (requested < 1 || requested > 7 || sigma < 1 || sigma > 8 ||
        theta < 0 || theta > 359 || wavelength < 1 || wavelength > 8 ||
        gamma < 0 || gamma > 4 || phase < -6 || phase > 6) return -1;

    size_t side = (size_t)requested;
    if ((side & 1u) == 0) ++side;
    const size_t output_bytes = side * side * 4;
    if (output == NULL || capacity < output_bytes) return -2;

    const double angle = ((double)theta / 180.0) * PI;
    const double cosine = cos(angle), sine = sin(angle);
    const size_t center = side / 2;
    size_t offset = 0;
    for (size_t y = 0; y < side; ++y) {
        const double py = (double)y - (double)center;
        for (size_t x = 0; x < side; ++x) {
            const double px = (double)x - (double)center;
            const double kernel_x = cosine * px + sine * py;
            const double kernel_y = -sine * px + cosine * py;
            const double exponent = -(kernel_x * kernel_x +
                (double)(gamma * gamma) * kernel_y * kernel_y) /
                (2.0 * (double)sigma * (double)sigma);
            const double phase_angle = 2.0 * PI * kernel_x /
                (double)wavelength + (double)phase;
            put_f32_le(output, offset, exp(exponent) * cos(phase_angle));
            offset += 4;
        }
    }
    return (int64_t)output_bytes;
}
