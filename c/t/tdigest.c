#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_SAMPLES 32u
#define MAX_QUERIES 4u
#define MAX_INPUT_LENGTH 45u
#define MAX_VALID_INPUT_LENGTH 44u
#define MAX_CENTROIDS 44u
#define MAX_OUTPUT_LENGTH 10u
#define TWO_PI 6.283185307179586476925286766559

static int integer_in_range(double value, int low, int high) {
    return isfinite(value) && value >= (double)low && value <= (double)high && value == trunc(value);
}

static double interpolate(double x0, double y0, double x1, double y1, double x) {
    if (x1 <= x0) return y1;
    return y0 + (x - x0) / (x1 - x0) * (y1 - y0);
}

static double quantile_limit(double compression, double q) {
    if (q < 0.0) q = 0.0;
    if (q > 1.0) q = 1.0;
    const double k = compression / TWO_PI * asin(2.0 * q - 1.0) + 1.0;
    const double angle = k * TWO_PI / compression;
    if (angle >= 1.57079632679489661923) return 1.0;
    if (angle <= -1.57079632679489661923) return 0.0;
    return (sin(angle) + 1.0) / 2.0;
}

static double quantile(double q, const double *means, const double *weights, size_t centroid_count,
                       double total_weight, double minimum, double maximum) {
    if (centroid_count == 1) return means[0];
    const double index = q * total_weight;
    if (index <= 0.0) return minimum;
    if (index >= total_weight) return maximum;
    double previous_value = minimum;
    double previous_index = 0.0;
    double current_index = 0.0;
    for (size_t i = 0; i < centroid_count; ++i) {
        current_index += i == 0 ? weights[i] / 2.0 : (weights[i - 1] + weights[i]) / 2.0;
        if (index < current_index)
            return interpolate(previous_index, previous_value, current_index, means[i], index);
        previous_value = means[i];
        previous_index = current_index;
    }
    return interpolate(previous_index, previous_value, total_weight, maximum, index);
}

static double cdf(double value, const double *means, const double *weights, size_t centroid_count,
                  double total_weight, double minimum, double maximum) {
    if (value < minimum) return 0.0;
    if (value > maximum) return 1.0;
    if (maximum <= minimum) return 0.5;
    double previous_value = minimum;
    double previous_index = 0.0;
    double current_index = 0.0;
    for (size_t i = 0; i < centroid_count; ++i) {
        current_index += i == 0 ? weights[i] / 2.0 : (weights[i - 1] + weights[i]) / 2.0;
        if (value < means[i])
            return interpolate(previous_value, previous_index, means[i], current_index, value) / total_weight;
        previous_value = means[i];
        previous_index = current_index;
    }
    return interpolate(previous_value, previous_index, maximum, total_weight, value) / total_weight;
}

int64_t tdigest(const double *input, size_t input_length, double *output, size_t output_capacity) {
    if (input == NULL || input_length < 7u || input_length > MAX_INPUT_LENGTH) return -1;
    for (size_t i = 0; i < input_length; ++i) if (!isfinite(input[i])) return -1;
    if (!integer_in_range(input[0], 10, 20) || !integer_in_range(input[1], 1, (int)MAX_SAMPLES)) return -1;
    const size_t sample_count = (size_t)input[1];
    const size_t q_count_index = 2u + sample_count;
    if (q_count_index >= input_length || !integer_in_range(input[q_count_index], 1, (int)MAX_QUERIES)) return -1;
    const size_t q_count = (size_t)input[q_count_index];
    const size_t q_start = q_count_index + 1u;
    const size_t cdf_count_index = q_start + q_count;
    if (cdf_count_index >= input_length || !integer_in_range(input[cdf_count_index], 1, (int)MAX_QUERIES)) return -1;
    const size_t cdf_count = (size_t)input[cdf_count_index];
    const size_t cdf_start = cdf_count_index + 1u;
    if (input_length != cdf_start + cdf_count || input_length > MAX_VALID_INPUT_LENGTH) return -1;

    double sorted[MAX_SAMPLES];
    double probabilities[MAX_QUERIES];
    double cdf_values[MAX_QUERIES];
    for (size_t i = 0; i < sample_count; ++i) {
        const double value = input[2u + i];
        if (!integer_in_range(value, -8, 8)) return -1;
        sorted[i] = value;
    }
    for (size_t i = 0; i < q_count; ++i) {
        const double q = input[q_start + i];
        if (q < 0.0 || q > 1.0 || q * 4.0 != trunc(q * 4.0)) return -1;
        probabilities[i] = q;
    }
    for (size_t i = 0; i < cdf_count; ++i) {
        const double value = input[cdf_start + i];
        if (!integer_in_range(value, -8, 8)) return -1;
        cdf_values[i] = value;
    }

    for (size_t i = 1; i < sample_count; ++i) {
        const double value = sorted[i];
        size_t j = i;
        while (j > 0 && sorted[j - 1] > value) { sorted[j] = sorted[j - 1]; --j; }
        sorted[j] = value;
    }
    const double compression = input[0];
    const double total_weight = (double)sample_count;
    const size_t centroid_capacity = 2u * ((size_t)compression + 2u);
    double means[MAX_CENTROIDS];
    double weights[MAX_CENTROIDS];
    size_t last = 0;
    means[0] = sorted[0];
    weights[0] = 1.0;
    double closed_weight = 0.0;
    double weight_limit = total_weight * quantile_limit(compression, 0.0);
    for (size_t i = 1; i < sample_count; ++i) {
        const double projected = weights[last] + 1.0;
        const int room_left = closed_weight + projected <= weight_limit;
        if (room_left || last == centroid_capacity - 1u) {
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
    const size_t centroid_count = last + 1u;
    const double minimum = sorted[0];
    const double maximum = sorted[sample_count - 1u];
    double staged[MAX_OUTPUT_LENGTH];
    staged[0] = (double)q_count;
    for (size_t i = 0; i < q_count; ++i)
        staged[1u + i] = quantile(probabilities[i], means, weights, centroid_count, total_weight, minimum, maximum);
    staged[1u + q_count] = (double)cdf_count;
    for (size_t i = 0; i < cdf_count; ++i)
        staged[2u + q_count + i] = cdf(cdf_values[i], means, weights, centroid_count, total_weight, minimum, maximum);
    const size_t result_length = q_count + cdf_count + 2u;
    if (output == NULL || output_capacity < result_length) return -2;
    for (size_t i = 0; i < result_length; ++i) output[i] = staged[i];
    return (int64_t)result_length;
}
