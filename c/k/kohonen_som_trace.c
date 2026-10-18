#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_NODE_COUNT 8
#define MAX_FEATURE_COUNT 4
#define MAX_RADIUS 8
#define MIN_ALPHA_CODE 1
#define MAX_ALPHA_CODE 16
#define MAX_PARSEABLE_INPUT_LENGTH 41
#define MAX_OUTPUT_ELEMENTS 32

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

static int exact_integer_in_range(double value, int64_t minimum, int64_t maximum,
                                  int64_t *integer)
{
    if (!isfinite(value) || value < (double)minimum || value > (double)maximum) return 0;
    const int64_t converted = (int64_t)value;
    if ((double)converted != value) return 0;
    *integer = converted;
    return 1;
}

int64_t kohonen_som_trace(const double *input, size_t input_length,
                          double *output, size_t output_capacity)
{
    if (input == NULL || input_length < 4 || input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;

    int64_t node_count_value;
    int64_t feature_count_value;
    int64_t radius_value;
    int64_t alpha_code_value;
    if (!exact_integer_in_range(input[0], 1, MAX_NODE_COUNT, &node_count_value) ||
        !exact_integer_in_range(input[1], 1, MAX_FEATURE_COUNT, &feature_count_value) ||
        !exact_integer_in_range(input[2], 0, MAX_RADIUS, &radius_value) ||
        !exact_integer_in_range(input[3], MIN_ALPHA_CODE, MAX_ALPHA_CODE, &alpha_code_value)) return -1;

    const size_t node_count = (size_t)node_count_value;
    const size_t feature_count = (size_t)feature_count_value;
    const size_t radius = (size_t)radius_value;
    const size_t weight_count = node_count * feature_count;
    const size_t expected_length = 4 + feature_count + weight_count;
    if (input_length != expected_length) return -1;

    double sample[MAX_FEATURE_COUNT] = {0.0};
    double weights[MAX_OUTPUT_ELEMENTS] = {0.0};
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

    double distances[MAX_NODE_COUNT] = {0.0};
    for (size_t node = 0; node < node_count; ++node) {
        double distance = 0.0;
        for (size_t feature = 0; feature < feature_count; ++feature) {
            const double difference = rounded_subtract(weights[node * feature_count + feature], sample[feature]);
            const double squared = rounded_multiply(difference, difference);
            distance = rounded_add(distance, squared);
        }
        if (!isfinite(distance)) return -1;
        distances[node] = distance;
    }

    size_t best_node = 0;
    for (size_t node = 1; node < node_count; ++node) {
        if (distances[node] < distances[best_node]) best_node = node;
    }

    const size_t from_node = best_node > radius ? best_node - radius : 0;
    const size_t candidate_to_node = best_node + radius + 1;
    const size_t to_node = candidate_to_node < node_count ? candidate_to_node : node_count;
    const double alpha = (double)alpha_code_value / 16.0;
    for (size_t node = from_node; node < to_node; ++node) {
        for (size_t feature = 0; feature < feature_count; ++feature) {
            const size_t index = node * feature_count + feature;
            const double difference = rounded_subtract(sample[feature], weights[index]);
            const double adjustment = rounded_multiply(alpha, difference);
            const double value = rounded_add(weights[index], adjustment);
            if (!isfinite(value)) return -1;
            weights[index] = value;
        }
    }

    double staged[MAX_OUTPUT_ELEMENTS];
    for (size_t index = 0; index < weight_count; ++index) staged[index] = weights[index];
    if (output == NULL || output_capacity < weight_count) return -2;
    for (size_t index = 0; index < weight_count; ++index) output[index] = staged[index];
    return (int64_t)weight_count;
}
