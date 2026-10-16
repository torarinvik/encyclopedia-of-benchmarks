#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_samples = 16;
constexpr std::size_t max_input_length = 19;
constexpr double pi = 3.14159265358979323846264338327950288;

double pdf(double value, double mean, double variance) {
    const double difference = value - mean;
    return std::exp(-(difference * difference) / (2.0 * variance))
           / std::sqrt(2.0 * pi * variance);
}
}

extern "C" std::int64_t gaussian_mixture_model(const std::int64_t *values,
                                               std::size_t length,
                                               std::uint8_t *output,
                                               std::size_t capacity) {
    if (!values || length < 3 || length > max_input_length) return -1;
    const auto count_value = values[0], max_iterations = values[1], tolerance_micro = values[2];
    if (count_value < 2 || count_value > 16 || max_iterations < 1 || max_iterations > 20
            || tolerance_micro < 1 || tolerance_micro > 1000
            || length != 3 + static_cast<std::size_t>(count_value)) return -1;
    const auto count = static_cast<std::size_t>(count_value);
    double data[max_samples]{};
    std::int64_t previous_sample = -5001;
    for (std::size_t i = 0; i < count; ++i) {
        const auto sample = values[3 + i];
        if (sample < -5000 || sample > 5000 || sample < previous_sample) return -1;
        previous_sample = sample;
        data[i] = static_cast<double>(sample) / 1000.0;
    }
    const auto required = count + 1;
    if (!output || capacity < required) return -2;

    double data_mean = 0.0;
    for (std::size_t i = 0; i < count; ++i) data_mean += data[i];
    data_mean /= static_cast<double>(count);
    double variance = 0.0;
    for (std::size_t i = 0; i < count; ++i) {
        const double difference = data[i] - data_mean;
        variance += difference * difference;
    }
    variance = variance / static_cast<double>(count - 1) + 1e-6;
    double weights[2] = {0.5, 0.5};
    double means[2] = {data[0], data[count - 1]};
    double variances[2] = {variance, variance};
    double responsibilities[2][max_samples]{};
    const double tolerance = static_cast<double>(tolerance_micro) / 1000000.0;
    double previous_likelihood = 0.0;
    bool has_previous_likelihood = false;
    std::size_t iterations = 0;

    for (std::size_t iteration = 0; iteration < static_cast<std::size_t>(max_iterations); ++iteration) {
        double component_counts[2] = {0.0, 0.0};
        for (std::size_t i = 0; i < count; ++i) {
            const double probability0 = weights[0] * pdf(data[i], means[0], variances[0]);
            const double probability1 = weights[1] * pdf(data[i], means[1], variances[1]);
            const double total = probability0 + probability1;
            if (total == 0.0) return -1;
            responsibilities[0][i] = probability0 / total;
            responsibilities[1][i] = probability1 / total;
            component_counts[0] += responsibilities[0][i];
            component_counts[1] += responsibilities[1][i];
        }
        if (component_counts[0] <= 0.0 || component_counts[1] <= 0.0) return -1;
        for (std::size_t component = 0; component < 2; ++component) {
            weights[component] = component_counts[component] / static_cast<double>(count);
            double weighted_sum = 0.0;
            for (std::size_t i = 0; i < count; ++i)
                weighted_sum += responsibilities[component][i] * data[i];
            means[component] = weighted_sum / component_counts[component];
            double covariance = 0.0;
            for (std::size_t i = 0; i < count; ++i) {
                const double difference = data[i] - means[component];
                covariance += responsibilities[component][i] * difference * difference;
            }
            variances[component] = covariance / component_counts[component] + 1e-6;
        }
        double likelihood = 0.0;
        for (std::size_t i = 0; i < count; ++i) {
            const double density = weights[0] * pdf(data[i], means[0], variances[0])
                                   + weights[1] * pdf(data[i], means[1], variances[1]);
            likelihood += std::log(density + 1e-12);
        }
        iterations = iteration + 1;
        if (has_previous_likelihood && std::abs(likelihood - previous_likelihood) < tolerance) break;
        previous_likelihood = likelihood;
        has_previous_likelihood = true;
    }
    output[0] = static_cast<std::uint8_t>(iterations);
    for (std::size_t i = 0; i < count; ++i) {
        const double probability0 = weights[0] * pdf(data[i], means[0], variances[0]);
        const double probability1 = weights[1] * pdf(data[i], means[1], variances[1]);
        output[i + 1] = static_cast<std::uint8_t>(probability0 >= probability1 ? 0 : 1);
    }
    return static_cast<std::int64_t>(required);
}
