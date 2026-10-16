#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_COUNT = 256;
constexpr std::size_t MAX_INPUT_LENGTH = 1 + 3 * MAX_COUNT;
constexpr double INVALID_RESULT = -1.0e300;
}

extern "C" double gaussian_negative_log_likelihood_loss(const std::int64_t *values, std::size_t length) noexcept
{
    if (values == nullptr || length < 4 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    const std::int64_t count_value = values[0];
    if (count_value < 1 || count_value > static_cast<std::int64_t>(MAX_COUNT)) return INVALID_RESULT;
    const std::size_t count = static_cast<std::size_t>(count_value);
    if (length != 1 + 3 * count) return INVALID_RESULT;
    double total = 0.0;
    for (std::size_t i = 0; i < count; ++i) {
        const std::int64_t y_scaled = values[1 + i], mu_scaled = values[1 + count + i];
        const std::int64_t variance_nano = values[1 + 2 * count + i];
        if (y_scaled < -1000000 || y_scaled > 1000000 || mu_scaled < -1000000 || mu_scaled > 1000000 ||
            variance_nano < 1 || variance_nano > 1000000000) return INVALID_RESULT;
        const double y = static_cast<double>(y_scaled) / 1000000.0;
        const double mu = static_cast<double>(mu_scaled) / 1000000.0;
        double variance = static_cast<double>(variance_nano) / 1000000000.0;
        if (variance < 1e-6) variance = 1e-6;
        const double residual = y - mu;
        const double loss_var = 0.5 * std::log(variance);
        const double loss_exp = 0.5 * ((residual * residual) / variance);
        total += loss_var + loss_exp;
    }
    return total / static_cast<double>(count);
}
