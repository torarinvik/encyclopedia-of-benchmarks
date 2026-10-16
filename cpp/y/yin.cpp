#include <cstddef>
#include <cstdint>

namespace {
constexpr double INVALID_RESULT = -1.0e300;
constexpr std::size_t MAX_SAMPLES = 256;
constexpr std::size_t MAX_LAG = 64;
}

extern "C" double yin(const std::int64_t *input, std::size_t length)
{
    if (input == nullptr || length < 7 || length > MAX_SAMPLES + 5) return INVALID_RESULT;
    const auto count_v = input[0], rate_v = input[1], min_hz_v = input[2], max_hz_v = input[3], threshold_v = input[4];
    if (count_v < 2 || count_v > static_cast<std::int64_t>(MAX_SAMPLES) || length != static_cast<std::size_t>(count_v) + 5 ||
        rate_v < 1 || rate_v > 192000 || min_hz_v < 1 || max_hz_v <= min_hz_v || max_hz_v > rate_v / 2 ||
        threshold_v < 1 || threshold_v > 999999) return INVALID_RESULT;
    const auto count = static_cast<std::size_t>(count_v);
    const auto min_lag = static_cast<std::size_t>(rate_v / max_hz_v);
    const auto max_lag = static_cast<std::size_t>(rate_v / min_hz_v);
    if (min_lag < 1 || min_lag > max_lag || max_lag > MAX_LAG || max_lag >= count) return INVALID_RESULT;
    double samples[MAX_SAMPLES];
    for (std::size_t i = 0; i < count; ++i) {
        if (input[i + 5] < -32768 || input[i + 5] > 32767) return INVALID_RESULT;
        samples[i] = static_cast<double>(input[i + 5]);
    }
    double cmndf[MAX_LAG + 1]{};
    cmndf[0] = 1.0;
    double cumulative = 0.0;
    for (std::size_t lag = 1; lag <= max_lag; ++lag) {
        double difference = 0.0;
        for (std::size_t i = 0; i < count - lag; ++i) {
            const double delta = samples[i] - samples[i + lag];
            difference += delta * delta;
        }
        cumulative += difference;
        cmndf[lag] = static_cast<double>(lag) * difference / (cumulative == 0.0 ? 1e-10 : cumulative);
    }
    const double threshold = static_cast<double>(threshold_v) / 1000000.0;
    std::size_t lag = min_lag;
    while (lag <= max_lag) {
        if (cmndf[lag] < threshold) {
            while (lag < max_lag && cmndf[lag + 1] < cmndf[lag]) ++lag;
            const std::size_t x0 = lag > 0 ? lag - 1 : 0;
            const std::size_t x2 = lag + 1 <= max_lag ? lag + 1 : max_lag;
            const double s0 = cmndf[x0], s1 = cmndf[lag], s2 = cmndf[x2];
            const double denominator = s0 - 2.0 * s1 + s2;
            const double refined = denominator == 0.0 ? static_cast<double>(lag) : static_cast<double>(lag) + (s0 - s2) / (2.0 * denominator);
            if (!(refined > 0.0)) return INVALID_RESULT;
            return static_cast<double>(rate_v) / refined;
        }
        ++lag;
    }
    return INVALID_RESULT;
}
