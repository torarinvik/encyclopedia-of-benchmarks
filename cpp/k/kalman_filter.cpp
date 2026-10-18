#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_steps = 12;
constexpr std::size_t max_parseable_length = 64;
constexpr double scale = 1000000.0;
}

extern "C" std::int64_t kalman_filter(const double *input, std::size_t length,
    double *output, std::size_t output_capacity) {
    if (input == nullptr || length < 5 || length > max_parseable_length) return -1;
    for (std::size_t index = 0; index < length; ++index) {
        if (!std::isfinite(input[index]) || std::trunc(input[index]) != input[index]) return -1;
    }
    const double raw_steps = input[4];
    if (raw_steps < 1.0 || raw_steps > static_cast<double>(max_steps)) return -1;
    const auto steps = static_cast<std::size_t>(raw_steps);
    if (length != 5 + steps) return -1;
    if (input[0] < -1000000000.0 || input[0] > 1000000000.0 ||
        input[1] < 0.0 || input[1] > 1000000000000.0 ||
        input[2] < 0.0 || input[2] > 1000000000000.0 ||
        input[3] < 1.0 || input[3] > 1000000000000.0) return -1;
    for (std::size_t index = 0; index < steps; ++index) {
        const double measurement = input[5 + index];
        if (measurement < -1000000000.0 || measurement > 1000000000.0) return -1;
    }

    const auto required = 3 * steps;
    if (output == nullptr || output_capacity < required) return -2;
    double estimate = input[0] / scale;
    double covariance = input[1] / scale;
    const double process_noise = input[2] / scale;
    const double measurement_noise = input[3] / scale;
    for (std::size_t step = 0; step < steps; ++step) {
        const double measurement = input[5 + step] / scale;
        estimate += 0.0;
        covariance += process_noise;
        const double innovation_variance = covariance + measurement_noise;
        const double gain = covariance / innovation_variance;
        estimate += gain * (measurement - estimate);
        covariance = covariance * measurement_noise / innovation_variance;
        output[3 * step] = estimate;
        output[3 * step + 1] = covariance;
        output[3 * step + 2] = gain;
    }
    return static_cast<std::int64_t>(required);
}
