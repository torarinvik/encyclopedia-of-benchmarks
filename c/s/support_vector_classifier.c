/* Bounded port of the pinned Rust projected-gradient SVC. */
#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_N 8
#define MAX_D 4
#define MAX_Q 16
#define MAX_INPUT_VALUES 108

static double kernel_value(const double *left, const double *right, int dimension, int kind)
{
    if (kind == 0) {
        double total = 0.0;
        for (int i = 0; i < dimension; ++i) total += left[i] * right[i];
        return total;
    }
    double norm_squared = 0.0;
    for (int i = 0; i < dimension; ++i) {
        const double difference = left[i] - right[i];
        norm_squared += difference * difference;
    }
    return exp(-norm_squared);
}

static int64_t fit_predict(const int *labels, const double training[MAX_N][MAX_D],
                           const double testing[MAX_Q][MAX_D], int n, int dimension,
                           int query_count, int kind)
{
    double kernel_matrix[MAX_N][MAX_N];
    for (int i = 0; i < n; ++i)
        for (int j = 0; j < n; ++j)
            kernel_matrix[i][j] = kernel_value(training[i], training[j], dimension, kind);

    double optimum[MAX_N];
    for (int i = 0; i < n; ++i) optimum[i] = 0.5;
    for (int iteration = 0; iteration < 5000; ++iteration) {
        double gradient[MAX_N];
        for (int i = 0; i < n; ++i) {
            double total = 0.0;
            for (int j = 0; j < n; ++j)
                total += optimum[j] * (double)labels[j] * kernel_matrix[i][j];
            gradient[i] = (double)labels[i] * total - 1.0;
        }
        double old_optimum[MAX_N];
        for (int i = 0; i < n; ++i) old_optimum[i] = optimum[i];
        const double learning_rate = 0.1 / (1.0 + (double)iteration / 1000.0);
        for (int i = 0; i < n; ++i) {
            const double updated = optimum[i] - learning_rate * gradient[i];
            optimum[i] = updated < 0.0 ? 0.0 : (updated > 1.0 ? 1.0 : updated);
        }

        double sum_label_lambda = 0.0;
        for (int i = 0; i < n; ++i) sum_label_lambda += optimum[i] * (double)labels[i];
        double correction = sum_label_lambda / (double)n;
        for (int pass = 0; pass < 10; ++pass) {
            for (int i = 0; i < n; ++i) {
                const double updated = optimum[i] - correction * (double)labels[i];
                optimum[i] = updated < 0.0 ? 0.0 : (updated > 1.0 ? 1.0 : updated);
            }
            sum_label_lambda = 0.0;
            for (int i = 0; i < n; ++i) sum_label_lambda += optimum[i] * (double)labels[i];
            correction = sum_label_lambda / (double)n;
            if (fabs(sum_label_lambda) < 1e-10) break;
        }
        double difference_squared = 0.0;
        for (int i = 0; i < n; ++i) {
            const double difference = optimum[i] - old_optimum[i];
            difference_squared += difference * difference;
        }
        if (sqrt(difference_squared) < 1e-8) break;
    }

    double offset_total = 0.0;
    int offset_count = 0;
    for (int i = 0; i < n; ++i) {
        if (optimum[i] > 1e-5 && optimum[i] < 1.0 - 1e-5) {
            double kernel_sum = 0.0;
            for (int j = 0; j < n; ++j)
                kernel_sum += optimum[j] * (double)labels[j] *
                              kernel_value(training[j], training[i], dimension, kind);
            offset_total += (double)labels[i] - kernel_sum;
            ++offset_count;
        }
    }
    if (offset_count == 0) {
        for (int i = 0; i < n; ++i) {
            double kernel_sum = 0.0;
            for (int j = 0; j < n; ++j)
                kernel_sum += optimum[j] * (double)labels[j] *
                              kernel_value(training[j], training[i], dimension, kind);
            offset_total += (double)labels[i] - kernel_sum;
        }
        offset_total /= (double)n;
    } else {
        offset_total /= (double)offset_count;
    }

    int64_t mask = 0;
    for (int i = 0; i < query_count; ++i) {
        double total = 0.0;
        for (int j = 0; j < n; ++j)
            total += optimum[j] * (double)labels[j] *
                     kernel_value(training[j], testing[i], dimension, kind);
        if (total + offset_total >= 0.0) mask |= (int64_t)1 << i;
    }
    return mask;
}

int64_t support_vector_classifier(const int64_t *input, size_t length)
{
    if (input == NULL || length < 4 || length > MAX_INPUT_VALUES + 1) return -1;
    if (input[0] < 2 || input[0] > MAX_N || input[1] < 1 || input[1] > MAX_D ||
        input[2] < 0 || input[2] > 1 || input[3] < 1 || input[3] > MAX_Q) return -1;
    const int n = (int)input[0];
    const int dimension = (int)input[1];
    const int kind = (int)input[2];
    const int query_count = (int)input[3];
    const size_t expected_length = 4U + (size_t)n + (size_t)n * (size_t)dimension +
                                   (size_t)query_count * (size_t)dimension;
    if (length != expected_length) return -1;

    int labels[MAX_N];
    int saw_negative = 0, saw_positive = 0;
    for (int i = 0; i < n; ++i) {
        const int64_t label = input[4 + i];
        if (label != -1 && label != 1) return -1;
        labels[i] = (int)label;
        if (label < 0) saw_negative = 1;
        else saw_positive = 1;
    }
    if (!saw_negative || !saw_positive) return -1;

    double training[MAX_N][MAX_D] = {{0.0}};
    double testing[MAX_Q][MAX_D] = {{0.0}};
    const size_t training_start = 4U + (size_t)n;
    for (int i = 0; i < n; ++i) {
        for (int j = 0; j < dimension; ++j) {
            const int64_t value = input[training_start + (size_t)i * (size_t)dimension + (size_t)j];
            if (value < -4 || value > 4) return -1;
            training[i][j] = (double)value;
        }
    }
    const size_t testing_start = training_start + (size_t)n * (size_t)dimension;
    for (int i = 0; i < query_count; ++i) {
        for (int j = 0; j < dimension; ++j) {
            const int64_t value = input[testing_start + (size_t)i * (size_t)dimension + (size_t)j];
            if (value < -4 || value > 4) return -1;
            testing[i][j] = (double)value;
        }
    }
    return fit_predict(labels, training, testing, n, dimension, query_count, kind);
}
