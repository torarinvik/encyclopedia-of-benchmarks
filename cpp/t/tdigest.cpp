#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_samples = 32;
constexpr std::size_t max_queries = 4;
constexpr std::size_t max_input_length = 45;
constexpr std::size_t max_valid_input_length = 44;
constexpr std::size_t max_centroids = 44;
constexpr std::size_t max_output_length = 10;
constexpr double two_pi = 6.283185307179586476925286766559;

bool integer_in_range(double value, int low, int high) noexcept {
    return std::isfinite(value) && value >= static_cast<double>(low) &&
        value <= static_cast<double>(high) && value == std::trunc(value);
}

double interpolate(double x0, double y0, double x1, double y1, double x) noexcept {
    if (x1 <= x0) return y1;
    return y0 + (x - x0) / (x1 - x0) * (y1 - y0);
}

double quantile_limit(double compression, double q) noexcept {
    if (q < 0.0) q = 0.0;
    if (q > 1.0) q = 1.0;
    const double k = compression / two_pi * std::asin(2.0 * q - 1.0) + 1.0;
    const double angle = k * two_pi / compression;
    if (angle >= 1.57079632679489661923) return 1.0;
    if (angle <= -1.57079632679489661923) return 0.0;
    return (std::sin(angle) + 1.0) / 2.0;
}

double quantile(double q, const double *means, const double *weights, std::size_t centroid_count,
                double total_weight, double minimum, double maximum) noexcept {
    if (centroid_count == 1) return means[0];
    const double index = q * total_weight;
    if (index <= 0.0) return minimum;
    if (index >= total_weight) return maximum;
    double previous_value = minimum;
    double previous_index = 0.0;
    double current_index = 0.0;
    for (std::size_t i = 0; i < centroid_count; ++i) {
        current_index += i == 0 ? weights[i] / 2.0 : (weights[i - 1] + weights[i]) / 2.0;
        if (index < current_index)
            return interpolate(previous_index, previous_value, current_index, means[i], index);
        previous_value = means[i];
        previous_index = current_index;
    }
    return interpolate(previous_index, previous_value, total_weight, maximum, index);
}

double cdf(double value, const double *means, const double *weights, std::size_t centroid_count,
           double total_weight, double minimum, double maximum) noexcept {
    if (value < minimum) return 0.0;
    if (value > maximum) return 1.0;
    if (maximum <= minimum) return 0.5;
    double previous_value = minimum;
    double previous_index = 0.0;
    double current_index = 0.0;
    for (std::size_t i = 0; i < centroid_count; ++i) {
        current_index += i == 0 ? weights[i] / 2.0 : (weights[i - 1] + weights[i]) / 2.0;
        if (value < means[i])
            return interpolate(previous_value, previous_index, means[i], current_index, value) / total_weight;
        previous_value = means[i];
        previous_index = current_index;
    }
    return interpolate(previous_value, previous_index, maximum, total_weight, value) / total_weight;
}
}

extern "C" std::int64_t tdigest(const double *input, std::size_t input_length,
                                double *output, std::size_t output_capacity) noexcept {
    if (input == nullptr || input_length < 7 || input_length > max_input_length) return -1;
    for (std::size_t i = 0; i < input_length; ++i) if (!std::isfinite(input[i])) return -1;
    if (!integer_in_range(input[0], 10, 20) ||
        !integer_in_range(input[1], 1, static_cast<int>(max_samples))) return -1;
    const auto sample_count = static_cast<std::size_t>(input[1]);
    const std::size_t q_count_index = 2 + sample_count;
    if (q_count_index >= input_length || !integer_in_range(input[q_count_index], 1, static_cast<int>(max_queries))) return -1;
    const auto q_count = static_cast<std::size_t>(input[q_count_index]);
    const std::size_t q_start = q_count_index + 1;
    const std::size_t cdf_count_index = q_start + q_count;
    if (cdf_count_index >= input_length || !integer_in_range(input[cdf_count_index], 1, static_cast<int>(max_queries))) return -1;
    const auto cdf_count = static_cast<std::size_t>(input[cdf_count_index]);
    const std::size_t cdf_start = cdf_count_index + 1;
    if (input_length != cdf_start + cdf_count || input_length > max_valid_input_length) return -1;

    double sorted[max_samples];
    double probabilities[max_queries];
    double cdf_values[max_queries];
    for (std::size_t i = 0; i < sample_count; ++i) {
        const double value = input[2 + i];
        if (!integer_in_range(value, -8, 8)) return -1;
        sorted[i] = value;
    }
    for (std::size_t i = 0; i < q_count; ++i) {
        const double q = input[q_start + i];
        if (q < 0.0 || q > 1.0 || q * 4.0 != std::trunc(q * 4.0)) return -1;
        probabilities[i] = q;
    }
    for (std::size_t i = 0; i < cdf_count; ++i) {
        const double value = input[cdf_start + i];
        if (!integer_in_range(value, -8, 8)) return -1;
        cdf_values[i] = value;
    }
    for (std::size_t i = 1; i < sample_count; ++i) {
        const double value = sorted[i];
        std::size_t j = i;
        while (j > 0 && sorted[j - 1] > value) { sorted[j] = sorted[j - 1]; --j; }
        sorted[j] = value;
    }

    const double compression = input[0];
    const double total_weight = static_cast<double>(sample_count);
    const std::size_t centroid_capacity = 2 * (static_cast<std::size_t>(compression) + 2);
    double means[max_centroids];
    double weights[max_centroids];
    std::size_t last = 0;
    means[0] = sorted[0];
    weights[0] = 1.0;
    double closed_weight = 0.0;
    double weight_limit = total_weight * quantile_limit(compression, 0.0);
    for (std::size_t i = 1; i < sample_count; ++i) {
        const double projected = weights[last] + 1.0;
        const bool room_left = closed_weight + projected <= weight_limit;
        if (room_left || last == centroid_capacity - 1) {
            weights[last] = projected;
            means[last] += (sorted[i] - means[last]) / projected;
        } else {
            closed_weight += weights[last];
            weight_limit = total_weight * quantile_limit(compression, closed_weight / total_weight);
            ++last;
            means[last] = sorted[i];
            weights[last] = 1.0;
        }
    }
    const std::size_t centroid_count = last + 1;
    const double minimum = sorted[0];
    const double maximum = sorted[sample_count - 1];
    double staged[max_output_length];
    staged[0] = static_cast<double>(q_count);
    for (std::size_t i = 0; i < q_count; ++i)
        staged[1 + i] = quantile(probabilities[i], means, weights, centroid_count, total_weight, minimum, maximum);
    staged[1 + q_count] = static_cast<double>(cdf_count);
    for (std::size_t i = 0; i < cdf_count; ++i)
        staged[2 + q_count + i] = cdf(cdf_values[i], means, weights, centroid_count, total_weight, minimum, maximum);
    const std::size_t result_length = q_count + cdf_count + 2;
    if (output == nullptr || output_capacity < result_length) return -2;
    for (std::size_t i = 0; i < result_length; ++i) output[i] = staged[i];
    return static_cast<std::int64_t>(result_length);
}
