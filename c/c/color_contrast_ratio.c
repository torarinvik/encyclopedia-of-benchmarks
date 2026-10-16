#include <stddef.h>
#include <stdint.h>
#include <math.h>

#define INVALID_RESULT (-1.0e300)

static double component(int64_t channel)
{
    const double srgb = (double)channel / 255.0;
    if (srgb <= 0.03928) return srgb / 12.92;
    const double adjusted = (srgb + 0.055) / 1.055;
    return pow(adjusted, 2.4);
}

static double luminance(int64_t red, int64_t green, int64_t blue)
{
    return 0.2126 * component(red) + 0.7152 * component(green) + 0.0722 * component(blue);
}

double color_contrast_ratio(const int64_t *values, size_t length)
{
    if (values == NULL || length != 6) return INVALID_RESULT;
    for (size_t i = 0; i < 6; ++i) {
        if (values[i] < 0 || values[i] > 255) return INVALID_RESULT;
    }
    const double first = luminance(values[0], values[1], values[2]);
    const double second = luminance(values[3], values[4], values[5]);
    if (first > second) return (first + 0.05) / (second + 0.05);
    return (second + 0.05) / (first + 0.05);
}
