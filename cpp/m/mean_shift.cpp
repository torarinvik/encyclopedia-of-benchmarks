#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_POINTS 16
#define MAX_DIMENSION 3
#define MAX_INPUT_LENGTH 54
#define MAX_ITERATIONS 64
#define THRESHOLD_MARGIN 1.0e-6

static double distance_between(const double *a, const double *b, size_t dimensions) {
    double sum = 0.0;
    for (size_t d = 0; d < dimensions; ++d) {
        const double difference = a[d] - b[d];
        sum += difference * difference;
    }
    return pow(sum, 0.5);
}

static int near_threshold(double value, double threshold) {
    return fabs(value - threshold) < THRESHOLD_MARGIN;
}

extern "C" int64_t mean_shift(const double *input, size_t length, double *output, size_t capacity) {
    if (input == NULL || length < 5 || length > MAX_INPUT_LENGTH) return -1;
    for (size_t i = 0; i < length; ++i) if (!isfinite(input[i])) return -1;
    const double n_value = input[0], d_value = input[1], bandwidth = input[2];
    const double iteration_value = input[3], tolerance = input[4];
    if (trunc(n_value) != n_value || trunc(d_value) != d_value || trunc(iteration_value) != iteration_value) return -1;
    if (n_value < 1 || n_value > MAX_POINTS || d_value < 1 || d_value > MAX_DIMENSION ||
        iteration_value < 1 || iteration_value > MAX_ITERATIONS || bandwidth < 0.5 || bandwidth > 20.0 ||
        tolerance < 1.0e-5 || tolerance > 1.0e-2) return -1;
    const size_t n = (size_t)n_value, dimensions = (size_t)d_value, max_iterations = (size_t)iteration_value;
    if (length != 5 + n * dimensions) return -1;
    const double *data = input + 5;
    for (size_t i = 0; i < n * dimensions; ++i) if (data[i] < -10.0 || data[i] > 10.0) return -1;

    double candidates[MAX_POINTS * MAX_DIMENSION] = {0};
    double next[MAX_POINTS * MAX_DIMENSION] = {0};
    for (size_t i = 0; i < n * dimensions; ++i) candidates[i] = data[i];
    for (size_t iteration = 0; iteration < max_iterations; ++iteration) {
        for (size_t c = 0; c < n; ++c) {
            double sums[MAX_DIMENSION] = {0}; size_t neighbor_count = 0;
            for (size_t p = 0; p < n; ++p) {
                const double distance = distance_between(data + p * dimensions, candidates + c * dimensions, dimensions);
                if (near_threshold(distance, bandwidth)) return -1;
                if (distance <= bandwidth) {
                    ++neighbor_count;
                    for (size_t d = 0; d < dimensions; ++d) sums[d] += data[p * dimensions + d];
                }
            }
            for (size_t d = 0; d < dimensions; ++d)
                next[c * dimensions + d] = neighbor_count == 0 ? candidates[c * dimensions + d] : sums[d] / (double)neighbor_count;
        }
        int all_converged = 1;
        for (size_t c = 0; c < n; ++c) {
            const double movement = distance_between(candidates + c * dimensions, next + c * dimensions, dimensions);
            if (near_threshold(movement, tolerance)) return -1;
            if (movement >= tolerance) { all_converged = 0; break; }
        }
        if (all_converged) break;
        for (size_t i = 0; i < n * dimensions; ++i) candidates[i] = next[i];
    }

    double centroids[MAX_POINTS * MAX_DIMENSION] = {0}; size_t centroid_count = 0;
    for (size_t c = 0; c < n; ++c) {
        int keep = 1;
        for (size_t existing = 0; existing < centroid_count; ++existing) {
            const double distance = distance_between(candidates + c * dimensions, centroids + existing * dimensions, dimensions);
            if (near_threshold(distance, bandwidth)) return -1;
            if (distance < bandwidth) { keep = 0; break; }
        }
        if (keep) {
            for (size_t d = 0; d < dimensions; ++d) centroids[centroid_count * dimensions + d] = candidates[c * dimensions + d];
            ++centroid_count;
        }
    }
    double labels[MAX_POINTS];
    for (size_t p = 0; p < n; ++p) {
        size_t best_index = 0;
        double best_distance = distance_between(data + p * dimensions, centroids, dimensions);
        for (size_t c = 1; c < centroid_count; ++c) {
            const double distance = distance_between(data + p * dimensions, centroids + c * dimensions, dimensions);
            if (distance != best_distance && near_threshold(distance, best_distance)) return -1;
            if (distance < best_distance) { best_index = c; best_distance = distance; }
        }
        labels[p] = (double)best_index;
    }
    if (output == NULL || capacity < n) return -2;
    for (size_t i = 0; i < n; ++i) output[i] = labels[i];
    return (int64_t)n;
}
