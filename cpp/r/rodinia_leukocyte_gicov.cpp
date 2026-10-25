/* Clean-room bounded GICOV recurrence; complete applicable notice in package LICENSE.txt. */
#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kEllipses = 7;
constexpr std::size_t kMaxPoints = 16;
constexpr double kInvalid = -1.0e300;
float decode(std::int64_t raw) { return static_cast<float>(raw) / 1'000'000.0f; }
float addf(float a, float b) { return a + b; }
float subf(float a, float b) { return a - b; }
float mulf(float a, float b) { return a * b; }
float divf(float a, float b) { return a / b; }
}

extern "C" double rodinia_leukocyte_gicov(const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length < 1) return kInvalid;
    if (input[0] < 2 || input[0] > static_cast<std::int64_t>(kMaxPoints)) return kInvalid;
    const auto points = static_cast<std::size_t>(input[0]);
    if (length != 1 + kEllipses * points) return kInvalid;
    for (std::size_t i = 1; i < length; ++i)
        if (input[i] < -1'000'000 || input[i] > 1'000'000) return kInvalid;

    float maximum = 0.0f;
    for (std::size_t ellipse = 0; ellipse < kEllipses; ++ellipse) {
        float sum = 0.0f, mean = 0.0f, m2 = 0.0f;
        const std::size_t base = 1 + ellipse * points;
        for (std::size_t n = 0; n < points; ++n) {
            const float p = decode(input[base + n]);
            sum = addf(sum, p);
            const float delta = subf(p, mean);
            mean = addf(mean, divf(delta, static_cast<float>(n + 1)));
            m2 = addf(m2, mulf(delta, subf(p, mean)));
        }
        mean = divf(sum, static_cast<float>(points));
        const float variance = divf(m2, static_cast<float>(points - 1));
        if (!(variance > 0.0f) || !std::isfinite(variance)) return kInvalid;
        const float score = divf(mulf(mean, mean), variance);
        if (!std::isfinite(score)) return kInvalid;
        if (score > maximum) maximum = score;
    }
    return static_cast<double>(maximum);
}
