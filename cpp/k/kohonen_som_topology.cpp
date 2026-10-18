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

double rounded_divide(double left, double right) noexcept {
    volatile double result = left / right;
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

extern "C" std::int64_t kohonen_som_topology(const double* input, std::size_t input_length,
                                              double* output, std::size_t output_capacity) noexcept {
    constexpr std::size_t max_map_size = 4;
    constexpr std::size_t max_feature_count = 3;
    constexpr std::size_t max_parseable_input_length = 56;
    constexpr std::size_t max_output_elements = 49;
    if (input == nullptr || input_length < 4 || input_length > max_parseable_input_length) return -1;

    std::int64_t map_size_value;
    std::int64_t feature_count_value;
    std::int64_t radius_value;
    std::int64_t alpha_code_value;
    if (!exact_integer_in_range(input[0], 1, static_cast<std::int64_t>(max_map_size), map_size_value) ||
        !exact_integer_in_range(input[1], 1, static_cast<std::int64_t>(max_feature_count), feature_count_value) ||
        !exact_integer_in_range(input[2], 0, 8, radius_value) ||
        !exact_integer_in_range(input[3], 1, 16, alpha_code_value)) return -1;

    const auto map_size = static_cast<std::size_t>(map_size_value);
    const auto feature_count = static_cast<std::size_t>(feature_count_value);
    const auto radius = static_cast<std::size_t>(radius_value);
    const std::size_t weight_count = map_size * map_size * feature_count;
    if (input_length != 4 + feature_count + weight_count) return -1;

    double sample[max_feature_count]{};
    double weights[max_map_size * max_map_size * max_feature_count]{};
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

    double distances[max_map_size * max_map_size]{};
    for (std::size_t x = 0; x < map_size; ++x) {
        for (std::size_t y = 0; y < map_size; ++y) {
            double distance_squared = 0.0;
            for (std::size_t feature = 0; feature < feature_count; ++feature) {
                const std::size_t index = (x * map_size + y) * feature_count + feature;
                const double difference = rounded_subtract(weights[index], sample[feature]);
                const double squared = rounded_multiply(difference, difference);
                distance_squared = rounded_add(distance_squared, squared);
            }
            const double distance = std::sqrt(distance_squared);
            if (!std::isfinite(distance)) return -1;
            distances[x * map_size + y] = distance;
        }
    }

    std::size_t best_x = 0;
    std::size_t best_y = 0;
    double minimum_distance = distances[0];
    for (std::size_t x = 0; x < map_size; ++x) {
        for (std::size_t y = 0; y < map_size; ++y) {
            const double distance = distances[x * map_size + y];
            if (distance < minimum_distance) {
                minimum_distance = distance;
                best_x = x;
                best_y = y;
            }
        }
    }

    const std::size_t from_x = best_x > radius ? best_x - radius : 0;
    const std::size_t from_y = best_y > radius ? best_y - radius : 0;
    const std::size_t candidate_to_x = best_x + radius + 1;
    const std::size_t candidate_to_y = best_y + radius + 1;
    const std::size_t to_x = candidate_to_x < map_size ? candidate_to_x : map_size;
    const std::size_t to_y = candidate_to_y < map_size ? candidate_to_y : map_size;
    const double alpha = static_cast<double>(alpha_code_value) / 16.0;
    for (std::size_t x = from_x; x < to_x; ++x) {
        for (std::size_t y = from_y; y < to_y; ++y) {
            const int dx = static_cast<int>(best_x) - static_cast<int>(x);
            const int dy = static_cast<int>(best_y) - static_cast<int>(y);
            const int grid_distance_squared = dx * dx + dy * dy;
            const double two_alpha = rounded_multiply(2.0, alpha);
            const double denominator = rounded_multiply(two_alpha, alpha);
            const double exponent = rounded_divide(-static_cast<double>(grid_distance_squared), denominator);
            const double scale_factor = std::exp(exponent);
            if (!std::isfinite(scale_factor)) return -1;
            const double alpha_scale = rounded_multiply(alpha, scale_factor);

            for (std::size_t feature = 0; feature < feature_count; ++feature) {
                const std::size_t index = (x * map_size + y) * feature_count + feature;
                const double difference = rounded_subtract(sample[feature], weights[index]);
                const double adjustment = rounded_multiply(alpha_scale, difference);
                const double value = rounded_add(weights[index], adjustment);
                if (!std::isfinite(value)) return -1;
                weights[index] = value;
            }
        }
    }

    double staged[max_output_elements]{};
    staged[0] = minimum_distance;
    for (std::size_t index = 0; index < weight_count; ++index) {
        if (!std::isfinite(weights[index])) return -1;
        staged[index + 1] = weights[index];
    }
    const std::size_t output_length = weight_count + 1;
    if (output == nullptr || output_capacity < output_length) return -2;
    for (std::size_t index = 0; index < output_length; ++index) output[index] = staged[index];
    return static_cast<std::int64_t>(output_length);
}
