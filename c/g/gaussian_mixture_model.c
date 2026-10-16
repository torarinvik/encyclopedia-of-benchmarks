#include <math.h>
#include <stddef.h>
#include <stdint.h>

enum { MAX_SAMPLES = 16, MAX_INPUT_LENGTH = 19 };
static const double PI = 3.14159265358979323846264338327950288;

static double gmm_pdf(double value, double mean, double variance) {
    double difference = value - mean;
    return exp(-(difference * difference) / (2.0 * variance))
           / sqrt(2.0 * PI * variance);
}

int64_t gaussian_mixture_model(const int64_t *values, size_t length,
                               uint8_t *output, size_t capacity) {
    if (values == NULL || length < 3 || length > MAX_INPUT_LENGTH) return -1;
    int64_t count_value = values[0], max_iterations_value = values[1];
    int64_t tolerance_micro = values[2];
    if (count_value < 2 || count_value > MAX_SAMPLES
            || max_iterations_value < 1 || max_iterations_value > 20
            || tolerance_micro < 1 || tolerance_micro > 1000
            || length != 3 + (size_t)count_value) return -1;
    size_t count = (size_t)count_value;
    double data[MAX_SAMPLES];
    int64_t previous_sample = INT64_MIN;
    for (size_t i = 0; i < count; ++i) {
        int64_t sample = values[3 + i];
        if (sample < -5000 || sample > 5000 || sample < previous_sample) return -1;
        previous_sample = sample;
        data[i] = (double)sample / 1000.0;
    }
    size_t required = count + 1;
    if (output == NULL || capacity < required) return -2;

    double data_mean = 0.0;
    for (size_t i = 0; i < count; ++i) data_mean += data[i];
    data_mean /= (double)count;
    double variance = 0.0;
    for (size_t i = 0; i < count; ++i) {
        double difference = data[i] - data_mean;
        variance += difference * difference;
    }
    variance = variance / (double)(count - 1) + 1e-6;

    double weights[2] = {0.5, 0.5};
    double means[2] = {data[0], data[count - 1]};
    double variances[2] = {variance, variance};
    double responsibilities[2][MAX_SAMPLES] = {{0.0}};
    double tolerance = (double)tolerance_micro / 1000000.0;
    double previous_likelihood = 0.0;
    int has_previous_likelihood = 0;
    size_t iterations = 0;

    for (size_t iteration = 0; iteration < (size_t)max_iterations_value; ++iteration) {
        double component_counts[2] = {0.0, 0.0};
        for (size_t i = 0; i < count; ++i) {
            double probability0 = weights[0] * gmm_pdf(data[i], means[0], variances[0]);
            double probability1 = weights[1] * gmm_pdf(data[i], means[1], variances[1]);
            double total = probability0 + probability1;
            if (total == 0.0 || !isfinite(total)) return -1;
            responsibilities[0][i] = probability0 / total;
            responsibilities[1][i] = probability1 / total;
            component_counts[0] += responsibilities[0][i];
            component_counts[1] += responsibilities[1][i];
        }
        if (component_counts[0] <= 0.0 || component_counts[1] <= 0.0) return -1;
        for (size_t component = 0; component < 2; ++component) {
            weights[component] = component_counts[component] / (double)count;
            double weighted_sum = 0.0;
            for (size_t i = 0; i < count; ++i)
                weighted_sum += responsibilities[component][i] * data[i];
            means[component] = weighted_sum / component_counts[component];
            double covariance = 0.0;
            for (size_t i = 0; i < count; ++i) {
                double difference = data[i] - means[component];
                covariance += responsibilities[component][i] * difference * difference;
            }
            variances[component] = covariance / component_counts[component] + 1e-6;
        }

        double likelihood = 0.0;
        for (size_t i = 0; i < count; ++i) {
            double density = weights[0] * gmm_pdf(data[i], means[0], variances[0])
                             + weights[1] * gmm_pdf(data[i], means[1], variances[1]);
            likelihood += log(density + 1e-12);
        }
        iterations = iteration + 1;
        if (has_previous_likelihood
                && fabs(likelihood - previous_likelihood) < tolerance) break;
        previous_likelihood = likelihood;
        has_previous_likelihood = 1;
    }

    output[0] = (uint8_t)iterations;
    for (size_t i = 0; i < count; ++i) {
        double probability0 = weights[0] * gmm_pdf(data[i], means[0], variances[0]);
        double probability1 = weights[1] * gmm_pdf(data[i], means[1], variances[1]);
        output[i + 1] = (uint8_t)(probability0 >= probability1 ? 0 : 1);
    }
    return (int64_t)required;
}
