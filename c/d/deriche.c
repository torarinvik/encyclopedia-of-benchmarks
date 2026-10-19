#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_WIDTH 32
#define MAX_HEIGHT 32
#define MAX_PIXELS (MAX_WIDTH * MAX_HEIGHT)
#define INVALID_RESULT (-1e300)

static void filter_once(size_t width, size_t height, const float *image,
                        float *output, float *y1, float *y2) {
    const float alpha = 0.25f;
    const float exp_neg_alpha = expf(-alpha);
    const float difference = 1.0f - exp_neg_alpha;
    const float numerator = difference * difference;
    const float denominator_left = 1.0f + 2.0f * alpha * exp_neg_alpha;
    const float k = numerator / (denominator_left - expf(2.0f * alpha));
    const float a1 = k;
    const float a2 = k * exp_neg_alpha * (alpha - 1.0f);
    const float a3 = k * exp_neg_alpha * (alpha + 1.0f);
    const float a4 = -k * expf(-2.0f * alpha);
    const float a5 = k;
    const float a6 = a2;
    const float a7 = a3;
    const float a8 = a4;
    const float b1 = powf(2.0f, -alpha);
    const float b2 = -expf(-2.0f * alpha);

    for (size_t i = 0; i < width; ++i) {
        float ym1 = 0.0f, ym2 = 0.0f, xm1 = 0.0f;
        for (size_t j = 0; j < height; ++j) {
            const size_t at = i * height + j;
            float value = a1 * image[at] + a2 * xm1;
            value = value + b1 * ym1;
            value = value + b2 * ym2;
            y1[at] = value;
            xm1 = image[at]; ym2 = ym1; ym1 = value;
        }
    }
    for (size_t i = 0; i < width; ++i) {
        float yp1 = 0.0f, yp2 = 0.0f, xp1 = 0.0f, xp2 = 0.0f;
        for (size_t j = height; j > 0;) {
            --j;
            const size_t at = i * height + j;
            float value = a3 * xp1 + a4 * xp2;
            value = value + b1 * yp1;
            value = value + b2 * yp2;
            y2[at] = value;
            xp2 = xp1; xp1 = image[at]; yp2 = yp1; yp1 = value;
        }
    }
    for (size_t i = 0; i < width; ++i)
        for (size_t j = 0; j < height; ++j) {
            const size_t at = i * height + j;
            output[at] = 1.0f * (y1[at] + y2[at]);
        }
    for (size_t j = 0; j < height; ++j) {
        float tm1 = 0.0f, ym1 = 0.0f, ym2 = 0.0f;
        for (size_t i = 0; i < width; ++i) {
            const size_t at = i * height + j;
            float value = a5 * output[at] + a6 * tm1;
            value = value + b1 * ym1;
            value = value + b2 * ym2;
            y1[at] = value;
            tm1 = output[at]; ym2 = ym1; ym1 = value;
        }
    }
    for (size_t j = 0; j < height; ++j) {
        float tp1 = 0.0f, tp2 = 0.0f, yp1 = 0.0f, yp2 = 0.0f;
        for (size_t i = width; i > 0;) {
            --i;
            const size_t at = i * height + j;
            float value = a7 * tp1 + a8 * tp2;
            value = value + b1 * yp1;
            value = value + b2 * yp2;
            y2[at] = value;
            tp2 = tp1; tp1 = output[at]; yp2 = yp1; yp1 = value;
        }
    }
    for (size_t at = 0; at < width * height; ++at)
        output[at] = 1.0f * (y1[at] + y2[at]);
}

double deriche(const int64_t *values, size_t length) {
    if (values == NULL || length != 3 || values[0] < 1 || values[0] > MAX_WIDTH ||
        values[1] < 1 || values[1] > MAX_HEIGHT || values[2] < 1 || values[2] > 4)
        return INVALID_RESULT;
    const size_t width = (size_t)values[0], height = (size_t)values[1];
    float first[MAX_PIXELS], second[MAX_PIXELS], y1[MAX_PIXELS], y2[MAX_PIXELS];
    float *image = first, *output = second;
    for (size_t i = 0; i < width; ++i)
        for (size_t j = 0; j < height; ++j)
            image[i * height + j] = (float)((313 * i + 991 * j) % 65536) / 65535.0f;
    for (int64_t pass = 0; pass < values[2]; ++pass) {
        filter_once(width, height, image, output, y1, y2);
        float *swap = image; image = output; output = swap;
    }
    double checksum = 0.0;
    for (size_t at = 0; at < width * height; ++at) checksum += (double)image[at];
    return checksum;
}
