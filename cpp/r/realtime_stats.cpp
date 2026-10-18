#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr double INVALID_RESULT = -1.0e300;
constexpr std::size_t MAX_INPUT_LENGTH = 36;
constexpr std::int64_t MAX_SAMPLES = 32;
}

extern "C" double realtime_stats(const std::int64_t *values, std::size_t length) noexcept
{
    if (values == nullptr || length < 3 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    const std::int64_t variant = values[0];
    const std::int64_t statistic = values[1];
    const std::int64_t count = values[2];
    if (variant < 0 || variant > 2 || statistic < 0 || statistic > 2 ||
        count < 2 || count > MAX_SAMPLES || length != static_cast<std::size_t>(3 + count))
        return INVALID_RESULT;
    for (std::size_t i = 0; i < static_cast<std::size_t>(count); ++i)
        if (values[3 + i] < -64 || values[3 + i] > 64) return INVALID_RESULT;

    float mean32 = 0.0f;
    float variance32 = 0.0f;
    double mean64 = 0.0;
    double variance64 = 0.0;

    if (variant == 0) {
        float anchor = 0.0f;
        float ex = 0.0f;
        float ex2 = 0.0f;
        unsigned int n = 0;
        for (std::size_t i = 0; i < static_cast<std::size_t>(count); ++i) {
            const float x = static_cast<float>(values[3 + i]) / 16.0f;
            if (n == 0) anchor = x;
            ++n;
            const float tmp = x - anchor;
            ex += tmp;
            ex2 += tmp * tmp;
        }
        mean32 = anchor + ex / static_cast<float>(n);
        variance32 = (ex2 - (ex * ex) / static_cast<float>(n)) / static_cast<float>(n - 1);
    } else if (variant == 1) {
        float mu = 0.0f;
        float m = 0.0f;
        unsigned int n = 0;
        for (std::size_t i = 0; i < static_cast<std::size_t>(count); ++i) {
            const float x = static_cast<float>(values[3 + i]) / 16.0f;
            ++n;
            const float delta = x - mu;
            mu += delta / static_cast<float>(n);
            const float delta2 = x - mu;
            m += delta * delta2;
        }
        mean32 = mu;
        variance32 = m / static_cast<float>(n);
    } else {
        double mu = 0.0;
        double m = 0.0;
        unsigned int n = 0;
        for (std::size_t i = 0; i < static_cast<std::size_t>(count); ++i) {
            const float x32 = static_cast<float>(values[3 + i]) / 16.0f;
            const double x = static_cast<double>(x32);
            ++n;
            const double delta = x - mu;
            mu += delta / static_cast<double>(n);
            const double delta2 = x - mu;
            m += delta * delta2;
        }
        mean64 = mu;
        variance64 = m / static_cast<double>(n);
    }

    if (variant < 2) {
        if (statistic == 0) return static_cast<double>(mean32);
        if (statistic == 1) return static_cast<double>(variance32);
        return static_cast<double>(std::sqrt(variance32));
    }
    if (statistic == 0) return mean64;
    if (statistic == 1) return variance64;
    return std::sqrt(variance64);
}
