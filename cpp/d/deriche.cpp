#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_width = 32, max_height = 32;
constexpr std::size_t max_pixels = max_width * max_height;
constexpr double invalid_result = -1e300;
void filter_once(std::size_t width, std::size_t height, const float *image,
                 float *output, float *y1, float *y2) {
    const float alpha = 0.25f;
    const float exp_neg_alpha = std::exp(-alpha);
    const float difference = 1.0f - exp_neg_alpha;
    const float numerator = difference * difference;
    const float denominator_left = 1.0f + 2.0f * alpha * exp_neg_alpha;
    const float k = numerator / (denominator_left - std::exp(2.0f * alpha));
    const float a1 = k, a2 = k * exp_neg_alpha * (alpha - 1.0f);
    const float a3 = k * exp_neg_alpha * (alpha + 1.0f), a4 = -k * std::exp(-2.0f * alpha);
    const float a5 = k, a6 = a2, a7 = a3, a8 = a4;
    const float b1 = std::pow(2.0f, -alpha), b2 = -std::exp(-2.0f * alpha);
    for (std::size_t i = 0; i < width; ++i) {
        float ym1 = 0, ym2 = 0, xm1 = 0;
        for (std::size_t j = 0; j < height; ++j) {
            const auto at = i * height + j;
            float value = a1 * image[at] + a2 * xm1;
            value = value + b1 * ym1; value = value + b2 * ym2; y1[at] = value;
            xm1 = image[at]; ym2 = ym1; ym1 = value;
        }
    }
    for (std::size_t i = 0; i < width; ++i) {
        float yp1 = 0, yp2 = 0, xp1 = 0, xp2 = 0;
        for (std::size_t j = height; j > 0;) {
            --j; const auto at = i * height + j;
            float value = a3 * xp1 + a4 * xp2;
            value = value + b1 * yp1; value = value + b2 * yp2; y2[at] = value;
            xp2 = xp1; xp1 = image[at]; yp2 = yp1; yp1 = value;
        }
    }
    for (std::size_t i = 0; i < width; ++i)
        for (std::size_t j = 0; j < height; ++j) {
            const auto at = i * height + j; output[at] = 1.0f * (y1[at] + y2[at]);
        }
    for (std::size_t j = 0; j < height; ++j) {
        float tm1 = 0, ym1 = 0, ym2 = 0;
        for (std::size_t i = 0; i < width; ++i) {
            const auto at = i * height + j;
            float value = a5 * output[at] + a6 * tm1;
            value = value + b1 * ym1; value = value + b2 * ym2; y1[at] = value;
            tm1 = output[at]; ym2 = ym1; ym1 = value;
        }
    }
    for (std::size_t j = 0; j < height; ++j) {
        float tp1 = 0, tp2 = 0, yp1 = 0, yp2 = 0;
        for (std::size_t i = width; i > 0;) {
            --i; const auto at = i * height + j;
            float value = a7 * tp1 + a8 * tp2;
            value = value + b1 * yp1; value = value + b2 * yp2; y2[at] = value;
            tp2 = tp1; tp1 = output[at]; yp2 = yp1; yp1 = value;
        }
    }
    for (std::size_t at = 0; at < width * height; ++at) output[at] = 1.0f * (y1[at] + y2[at]);
}
}

extern "C" double deriche(const std::int64_t *values, std::size_t length) noexcept {
    if (!values || length != 3 || values[0] < 1 || values[0] > max_width ||
        values[1] < 1 || values[1] > max_height || values[2] < 1 || values[2] > 4) return invalid_result;
    const auto width = static_cast<std::size_t>(values[0]), height = static_cast<std::size_t>(values[1]);
    float first[max_pixels]{}, second[max_pixels]{}, y1[max_pixels]{}, y2[max_pixels]{};
    float *image = first, *output = second;
    for (std::size_t i = 0; i < width; ++i) for (std::size_t j = 0; j < height; ++j)
        image[i * height + j] = static_cast<float>((313 * i + 991 * j) % 65536) / 65535.0f;
    for (std::int64_t pass = 0; pass < values[2]; ++pass) {
        filter_once(width, height, image, output, y1, y2);
        auto *swap = image; image = output; output = swap;
    }
    double checksum = 0;
    for (std::size_t at = 0; at < width * height; ++at) checksum += static_cast<double>(image[at]);
    return checksum;
}
