#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_MAP_SIZE 4
#define MAX_FEATURE_COUNT 3
#define MAX_PARSEABLE_INPUT_LENGTH 56
#define MAX_OUTPUT_ELEMENTS 49

static double rounded_add(double left, double right)
{
    volatile double result = left + right;
    return result;
}

static double rounded_subtract(double left, double right)
{
    volatile double result = left - right;
    return result;
}

static double rounded_multiply(double left, double right)
{
    volatile double result = left * right;
    return result;
}

static double rounded_divide(double left, double right)
{
    volatile double result = left / right;
    return result;
}

static int exact_integer_in_range(double value, int64_t minimum, int64_t maximum,
                                  int64_t *integer)
{
    if (!isfinite(value) || value < (double)minimum || value > (double)maximum) return 0;
    const int64_t converted = (int64_t)value;
    if ((double)converted != value) return 0;
    *integer = converted;
    return 1;
}

int64_t kohonen_som_topology(const double *input, size_t input_length,
                             double *output, size_t output_capacity)
{
    if (input == NULL || input_length < 4 || input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;

    int64_t map_size_value;
    int64_t feature_count_value;
    int64_t radius_value;
    int64_t alpha_code_value;
    if (!exact_integer_in_range(input[0], 1, MAX_MAP_SIZE, &map_size_value) ||
        !exact_integer_in_range(input[1], 1, MAX_FEATURE_COUNT, &feature_count_value) ||
        !exact_integer_in_range(input[2], 0, 8, &radius_value) ||
        !exact_integer_in_range(input[3], 1, 16, &alpha_code_value)) return -1;

    const size_t map_size = (size_t)map_size_value;
    const size_t feature_count = (size_t)feature_count_value;
    const size_t radius = (size_t)radius_value;
    const size_t weight_count = map_size * map_size * feature_count;
    const size_t expected_length = 4 + feature_count + weight_count;
    if (input_length != expected_length) return -1;

    double sample[MAX_FEATURE_COUNT] = {0.0};
    double weights[MAX_MAP_SIZE * MAX_MAP_SIZE * MAX_FEATURE_COUNT] = {0.0};
    for (size_t feature = 0; feature < feature_count; ++feature) {
        int64_t integer;
        if (!exact_integer_in_range(input[4 + feature], -8, 8, &integer)) return -1;
        sample[feature] = (double)integer;
    }
    for (size_t index = 0; index < weight_count; ++index) {
        int64_t integer;
        if (!exact_integer_in_range(input[4 + feature_count + index], -8, 8, &integer)) return -1;
        weights[index] = (double)integer;
    }

    double distances[MAX_MAP_SIZE * MAX_MAP_SIZE] = {0.0};
    for (size_t x = 0; x < map_size; ++x) {
        for (size_t y = 0; y < map_size; ++y) {
            double distance_squared = 0.0;
            for (size_t feature = 0; feature < feature_count; ++feature) {
                const size_t index = (x * map_size + y) * feature_count + feature;
                const double difference = rounded_subtract(weights[index], sample[feature]);
                const double squared = rounded_multiply(difference, difference);
                distance_squared = rounded_add(distance_squared, squared);
            }
            const double distance = sqrt(distance_squared);
            if (!isfinite(distance)) return -1;
            distances[x * map_size + y] = distance;
        }
    }

    size_t best_x = 0;
    size_t best_y = 0;
    double minimum_distance = distances[0];
    for (size_t x = 0; x < map_size; ++x) {
        for (size_t y = 0; y < map_size; ++y) {
            const double distance = distances[x * map_size + y];
            if (distance < minimum_distance) {
                minimum_distance = distance;
                best_x = x;
                best_y = y;
            }
        }
    }

    const size_t from_x = best_x > radius ? best_x - radius : 0;
    const size_t from_y = best_y > radius ? best_y - radius : 0;
    const size_t candidate_to_x = best_x + radius + 1;
    const size_t candidate_to_y = best_y + radius + 1;
    const size_t to_x = candidate_to_x < map_size ? candidate_to_x : map_size;
    const size_t to_y = candidate_to_y < map_size ? candidate_to_y : map_size;
    const double alpha = (double)alpha_code_value / 16.0;
    for (size_t x = from_x; x < to_x; ++x) {
        for (size_t y = from_y; y < to_y; ++y) {
            const int dx = (int)best_x - (int)x;
            const int dy = (int)best_y - (int)y;
            const int grid_distance_squared = dx * dx + dy * dy;
            const double two_alpha = rounded_multiply(2.0, alpha);
            const double denominator = rounded_multiply(two_alpha, alpha);
            const double exponent = rounded_divide(-(double)grid_distance_squared, denominator);
            const double scale_factor = exp(exponent);
            if (!isfinite(scale_factor)) return -1;
            const double alpha_scale = rounded_multiply(alpha, scale_factor);

            for (size_t feature = 0; feature < feature_count; ++feature) {
                const size_t index = (x * map_size + y) * feature_count + feature;
                const double difference = rounded_subtract(sample[feature], weights[index]);
                const double adjustment = rounded_multiply(alpha_scale, difference);
                const double value = rounded_add(weights[index], adjustment);
                if (!isfinite(value)) return -1;
                weights[index] = value;
            }
        }
    }

    double staged[MAX_OUTPUT_ELEMENTS];
    staged[0] = minimum_distance;
    for (size_t index = 0; index < weight_count; ++index) {
        if (!isfinite(weights[index])) return -1;
        staged[index + 1] = weights[index];
    }
    const size_t output_length = weight_count + 1;
    if (output == NULL || output_capacity < output_length) return -2;
    for (size_t index = 0; index < output_length; ++index) output[index] = staged[index];
    return (int64_t)output_length;
}
