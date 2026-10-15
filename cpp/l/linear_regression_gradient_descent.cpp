// One-feature batch gradient descent with a zero-initialized model.
#include <cstddef>
#include <cstdint>

extern "C" double linear_regression_gradient_descent(const std::int64_t *values, std::size_t length) noexcept {
    constexpr std::int64_t max_observations = 64;
    constexpr std::int64_t max_epochs = 10000;
    constexpr double invalid_result = -1.0e300;
    if (values == nullptr || length < 7 || length > 131 || length % 2 == 0) return invalid_result;
    const auto count = values[0];
    const auto rate_microunits = values[1];
    const auto epochs = values[2];
    if (count < 2 || count > max_observations || length != 3 + 2 * static_cast<std::size_t>(count) ||
        rate_microunits < 1 || rate_microunits > 1000 || epochs < 1 || epochs > max_epochs) return invalid_result;
    for (std::size_t index = 0; index < static_cast<std::size_t>(count); ++index) {
        const auto x = values[3 + 2 * index];
        const auto y = values[4 + 2 * index];
        if (x < -10 || x > 10 || y < -100 || y > 100) return invalid_result;
    }

    const double alpha = static_cast<double>(rate_microunits) / 1000000.0;
    const double scale = alpha / static_cast<double>(count);
    double slope = 0.0;
    double intercept = 0.0;
    for (std::int64_t epoch = 0; epoch < epochs; ++epoch) {
        double slope_gradient = 0.0;
        double intercept_gradient = 0.0;
        for (std::size_t index = 0; index < static_cast<std::size_t>(count); ++index) {
            const double x = static_cast<double>(values[3 + 2 * index]);
            const double y = static_cast<double>(values[4 + 2 * index]);
            const double error = slope * x + intercept - y;
            slope_gradient += error * x;
            intercept_gradient += error;
        }
        slope -= scale * slope_gradient;
        intercept -= scale * intercept_gradient;
    }
    return slope;
}
