#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
double rounded_add(double left, double right) noexcept {
    volatile double result = left + right;
    return result;
}

double rounded_subtract(double left, double right) noexcept {
    volatile double result = left - right;
    return result;
}

double rounded_multiply(double left, double right) noexcept {
    volatile double result = left * right;
    return result;
}

bool exact_integer_in_range(double value, std::int64_t minimum, std::int64_t maximum,
                            std::int64_t& integer) noexcept {
    if (!std::isfinite(value) || value < static_cast<double>(minimum) ||
        value > static_cast<double>(maximum)) return false;
    const auto converted = static_cast<std::int64_t>(value);
    if (static_cast<double>(converted) != value) return false;
    integer = converted;
    return true;
}
}

extern "C" std::int64_t kohonen_som_trace(const double* input, std::size_t input_length,
                                            double* output, std::size_t output_capacity) noexcept {
    constexpr std::size_t max_node_count = 8;
    constexpr std::size_t max_feature_count = 4;
    constexpr std::size_t max_radius = 8;
    constexpr std::int64_t min_alpha_code = 1;
    constexpr std::int64_t max_alpha_code = 16;
    constexpr std::size_t max_parseable_input_length = 41;
    constexpr std::size_t max_output_elements = 32;
    if (input == nullptr || input_length < 4 || input_length > max_parseable_input_length) return -1;

    std::int64_t node_count_value;
    std::int64_t feature_count_value;
    std::int64_t radius_value;
    std::int64_t alpha_code_value;
    if (!exact_integer_in_range(input[0], 1, static_cast<std::int64_t>(max_node_count), node_count_value) ||
        !exact_integer_in_range(input[1], 1, static_cast<std::int64_t>(max_feature_count), feature_count_value) ||
        !exact_integer_in_range(input[2], 0, static_cast<std::int64_t>(max_radius), radius_value) ||
        !exact_integer_in_range(input[3], min_alpha_code, max_alpha_code, alpha_code_value)) return -1;

    const auto node_count = static_cast<std::size_t>(node_count_value);
    const auto feature_count = static_cast<std::size_t>(feature_count_value);
    const auto radius = static_cast<std::size_t>(radius_value);
    const std::size_t weight_count = node_count * feature_count;
    if (input_length != 4 + feature_count + weight_count) return -1;

    double sample[max_feature_count]{};
    double weights[max_output_elements]{};
    for (std::size_t feature = 0; feature < feature_count; ++feature) {
        std::int64_t integer;
        if (!exact_integer_in_range(input[4 + feature], -8, 8, integer)) return -1;
        sample[feature] = static_cast<double>(integer);
    }
    for (std::size_t index = 0; index < weight_count; ++index) {
        std::int64_t integer;
        if (!exact_integer_in_range(input[4 + feature_count + index], -8, 8, integer)) return -1;
        weights[index] = static_cast<double>(integer);
    }

    double distances[max_node_count]{};
    for (std::size_t node = 0; node < node_count; ++node) {
        double distance = 0.0;
        for (std::size_t feature = 0; feature < feature_count; ++feature) {
            const double difference = rounded_subtract(weights[node * feature_count + feature], sample[feature]);
            const double squared = rounded_multiply(difference, difference);
            distance = rounded_add(distance, squared);
        }
        if (!std::isfinite(distance)) return -1;
        distances[node] = distance;
    }

    std::size_t best_node = 0;
    for (std::size_t node = 1; node < node_count; ++node) {
        if (distances[node] < distances[best_node]) best_node = node;
    }

    const std::size_t from_node = best_node > radius ? best_node - radius : 0;
    const std::size_t candidate_to_node = best_node + radius + 1;
    const std::size_t to_node = candidate_to_node < node_count ? candidate_to_node : node_count;
    const double alpha = static_cast<double>(alpha_code_value) / 16.0;
    for (std::size_t node = from_node; node < to_node; ++node) {
        for (std::size_t feature = 0; feature < feature_count; ++feature) {
            const std::size_t index = node * feature_count + feature;
            const double difference = rounded_subtract(sample[feature], weights[index]);
            const double adjustment = rounded_multiply(alpha, difference);
            const double value = rounded_add(weights[index], adjustment);
            if (!std::isfinite(value)) return -1;
            weights[index] = value;
        }
    }

    double staged[max_output_elements]{};
    for (std::size_t index = 0; index < weight_count; ++index) staged[index] = weights[index];
    if (output == nullptr || output_capacity < weight_count) return -2;
    for (std::size_t index = 0; index < weight_count; ++index) output[index] = staged[index];
    return static_cast<std::int64_t>(weight_count);
}
