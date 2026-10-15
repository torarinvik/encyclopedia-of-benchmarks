#include <cmath>
#include <cstddef>
#include <cstdint>

namespace { constexpr double INVALID_RESULT = -1.0e300; }

static float geometric_cdf(float p, std::int64_t k) {
    return 1.0f - std::pow(1.0f - p, static_cast<float>(k));
}

// Deterministic operations of the source's first-success geometric distribution.
extern "C" double geometric_dist(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length < 2) return INVALID_RESULT;
    const auto operation = values[0];
    const auto p_code = values[1];
    if (p_code < 0 || p_code > 2) return INVALID_RESULT;
    constexpr float probabilities[] = {0.25f, 0.5f, 0.75f};
    const float p = probabilities[p_code];
    if (operation >= 0 && operation <= 2) {
        if (length != 2) return INVALID_RESULT;
        if (operation == 0) return static_cast<double>(1.0f / p);
        const float variance = (1.0f - p) / (p * p);
        return static_cast<double>(operation == 1 ? variance : std::sqrt(variance));
    }
    if (operation == 3 || operation == 4) {
        if (length != 3) return INVALID_RESULT;
        const auto k = values[2];
        if (operation == 3 && (k < 1 || k > 16)) return INVALID_RESULT;
        if (operation == 4 && (k < 0 || k > 16)) return INVALID_RESULT;
        if (operation == 3)
            return static_cast<double>(std::pow(1.0f - p, static_cast<float>(k - 1)) * p);
        return static_cast<double>(geometric_cdf(p, k));
    }
    if (operation == 5) {
        if (length != 3 || values[2] < 0 || values[2] > 2) return INVALID_RESULT;
        constexpr float cdf_values[] = {0.25f, 0.5f, 0.75f};
        const float cdf = cdf_values[values[2]];
        return static_cast<double>(std::log(1.0f - cdf) / std::log(1.0f - p));
    }
    if (operation == 6) {
        if (length != 4) return INVALID_RESULT;
        const auto minimum = values[2];
        const auto maximum = values[3];
        if (minimum < 1 || maximum < minimum || maximum > 16) return INVALID_RESULT;
        const float lower = geometric_cdf(p, minimum - 1);
        const float upper = geometric_cdf(p, maximum);
        return static_cast<double>(upper - lower);
    }
    return INVALID_RESULT;
}
