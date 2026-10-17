module support_vector_classifier;

const int MAX_N = 8;
const int MAX_D = 4;
const int MAX_Q = 16;
const usz MAX_INPUT_VALUES = 108;

extern fn double exp(double value);
extern fn double sqrt(double value);
extern fn double fabs(double value);

fn double kernel_value(double* left, double* right, int dimension, int kind) {
    if (kind == 0) {
        double total = 0.0;
        for (int i = 0; i < dimension; ++i) total += left[i] * right[i];
        return total;
    }
    double norm_squared = 0.0;
    for (int i = 0; i < dimension; ++i) {
        double difference = left[i] - right[i];
        norm_squared += difference * difference;
    }
    return exp(-norm_squared);
}

fn long fit_predict(int* labels, double* training, double* testing,
                    int n, int dimension, int query_count, int kind) {
    double[MAX_N * MAX_N] kernel_matrix;
    for (int i = 0; i < n; ++i)
        for (int j = 0; j < n; ++j)
            kernel_matrix[i * MAX_N + j] = kernel_value(
                &training[i * MAX_D], &training[j * MAX_D], dimension, kind);

    double[MAX_N] optimum;
    for (int i = 0; i < n; ++i) optimum[i] = 0.5;
    for (int iteration = 0; iteration < 5000; ++iteration) {
        double[MAX_N] gradient;
        for (int i = 0; i < n; ++i) {
            double total = 0.0;
            for (int j = 0; j < n; ++j)
                total += optimum[j] * (double)labels[j] * kernel_matrix[i * MAX_N + j];
            gradient[i] = (double)labels[i] * total - 1.0;
        }
        double[MAX_N] old_optimum;
        for (int i = 0; i < n; ++i) old_optimum[i] = optimum[i];
        double learning_rate = 0.1 / (1.0 + (double)iteration / 1000.0);
        for (int i = 0; i < n; ++i) {
            double updated = optimum[i] - learning_rate * gradient[i];
            if (updated < 0.0) updated = 0.0;
            if (updated > 1.0) updated = 1.0;
            optimum[i] = updated;
        }
        double sum_label_lambda = 0.0;
        for (int i = 0; i < n; ++i) sum_label_lambda += optimum[i] * (double)labels[i];
        double correction = sum_label_lambda / (double)n;
        for (int pass = 0; pass < 10; ++pass) {
            for (int i = 0; i < n; ++i) {
                double updated = optimum[i] - correction * (double)labels[i];
                if (updated < 0.0) updated = 0.0;
                if (updated > 1.0) updated = 1.0;
                optimum[i] = updated;
            }
            sum_label_lambda = 0.0;
            for (int i = 0; i < n; ++i) sum_label_lambda += optimum[i] * (double)labels[i];
            correction = sum_label_lambda / (double)n;
            if (fabs(sum_label_lambda) < 1e-10) break;
        }
        double difference_squared = 0.0;
        for (int i = 0; i < n; ++i) {
            double difference = optimum[i] - old_optimum[i];
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
                kernel_sum += optimum[j] * (double)labels[j] * kernel_value(
                    &training[j * MAX_D], &training[i * MAX_D], dimension, kind);
            offset_total += (double)labels[i] - kernel_sum;
            offset_count += 1;
        }
    }
    if (offset_count == 0) {
        for (int i = 0; i < n; ++i) {
            double kernel_sum = 0.0;
            for (int j = 0; j < n; ++j)
                kernel_sum += optimum[j] * (double)labels[j] * kernel_value(
                    &training[j * MAX_D], &training[i * MAX_D], dimension, kind);
            offset_total += (double)labels[i] - kernel_sum;
        }
        offset_total /= (double)n;
    } else {
        offset_total /= (double)offset_count;
    }

    long mask = 0;
    for (int i = 0; i < query_count; ++i) {
        double total = 0.0;
        for (int j = 0; j < n; ++j)
            total += optimum[j] * (double)labels[j] * kernel_value(
                &training[j * MAX_D], &testing[i * MAX_D], dimension, kind);
        if (total + offset_total >= 0.0) mask |= (long)1 << i;
    }
    return mask;
}

fn long support_vector_classifier(long* input, usz length)
        @export("support_vector_classifier") {
    if (input == null || length < 4 || length > MAX_INPUT_VALUES + 1) return -1;
    if (input[0] < 2 || input[0] > MAX_N || input[1] < 1 || input[1] > MAX_D ||
        input[2] < 0 || input[2] > 1 || input[3] < 1 || input[3] > MAX_Q) return -1;
    int n = (int)input[0];
    int dimension = (int)input[1];
    int kind = (int)input[2];
    int query_count = (int)input[3];
    usz expected_length = 4 + (usz)n + (usz)n * (usz)dimension + (usz)query_count * (usz)dimension;
    if (length != expected_length) return -1;

    int[MAX_N] labels;
    bool saw_negative = false;
    bool saw_positive = false;
    for (int i = 0; i < n; ++i) {
        long label = input[4 + i];
        if (label != -1 && label != 1) return -1;
        labels[i] = (int)label;
        if (label < 0) saw_negative = true;
        else saw_positive = true;
    }
    if (!saw_negative || !saw_positive) return -1;

    double[MAX_N * MAX_D] training;
    double[MAX_Q * MAX_D] testing;
    usz training_start = 4 + (usz)n;
    for (int i = 0; i < n; ++i)
        for (int j = 0; j < dimension; ++j) {
            long value = input[training_start + (usz)i * (usz)dimension + (usz)j];
            if (value < -4 || value > 4) return -1;
            training[i * MAX_D + j] = (double)value;
        }
    usz testing_start = training_start + (usz)n * (usz)dimension;
    for (int i = 0; i < query_count; ++i)
        for (int j = 0; j < dimension; ++j) {
            long value = input[testing_start + (usz)i * (usz)dimension + (usz)j];
            if (value < -4 || value > 4) return -1;
            testing[i * MAX_D + j] = (double)value;
        }
    return fit_predict(&labels[0], &training[0], &testing[0], n, dimension, query_count, kind);
}
