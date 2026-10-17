#include <stddef.h>
#include <stdint.h>

#define MAX_PARSEABLE_INPUT_LENGTH 84
#define MAX_POINT_COUNT 16
#define MAX_DIMENSION 4
#define MAX_CLUSTER_COUNT 4
#define MAX_OUTPUT_ELEMENTS 32

static int bounded_integer(double value, int64_t minimum, int64_t maximum, int64_t *result)
{
    if (value != value || value < (double)minimum || value > (double)maximum) return 0;
    const int64_t integer = (int64_t)value;
    if ((double)integer != value) return 0;
    *result = integer;
    return 1;
}

int64_t k_means_clust(const double *input, size_t input_length,
                      double *output, size_t output_capacity)
{
    if (input == NULL || input_length < 3 || input_length > MAX_PARSEABLE_INPUT_LENGTH)
        return -1;

    int64_t point_count_value, dimension_value, cluster_count_value;
    if (!bounded_integer(input[0], 1, MAX_POINT_COUNT, &point_count_value) ||
        !bounded_integer(input[1], 1, MAX_DIMENSION, &dimension_value) ||
        !bounded_integer(input[2], 1, MAX_CLUSTER_COUNT, &cluster_count_value)) return -1;
    if (cluster_count_value > point_count_value) return -1;

    const size_t point_count = (size_t)point_count_value;
    const size_t dimension = (size_t)dimension_value;
    const size_t cluster_count = (size_t)cluster_count_value;
    const size_t data_start = 3;
    const size_t centroid_start = data_start + point_count * dimension;
    const size_t expected_length = centroid_start + cluster_count * dimension;
    if (input_length != expected_length) return -1;

    int64_t data[MAX_POINT_COUNT * MAX_DIMENSION];
    int64_t initial_centroids[MAX_CLUSTER_COUNT * MAX_DIMENSION];
    for (size_t index = 0; index < point_count * dimension; ++index) {
        if (!bounded_integer(input[data_start + index], -16, 16, &data[index])) return -1;
    }
    for (size_t index = 0; index < cluster_count * dimension; ++index) {
        if (!bounded_integer(input[centroid_start + index], -16, 16,
                             &initial_centroids[index])) return -1;
    }

    double staged[MAX_OUTPUT_ELEMENTS];
    int64_t counts[MAX_CLUSTER_COUNT] = {0};
    int64_t sums[MAX_CLUSTER_COUNT * MAX_DIMENSION] = {0};
    for (size_t point = 0; point < point_count; ++point) {
        size_t best_cluster = 0;
        int64_t best_distance = 0;
        for (size_t feature = 0; feature < dimension; ++feature) {
            const int64_t delta = data[point * dimension + feature] - initial_centroids[feature];
            best_distance += delta * delta;
        }
        for (size_t cluster = 1; cluster < cluster_count; ++cluster) {
            int64_t distance = 0;
            for (size_t feature = 0; feature < dimension; ++feature) {
                const int64_t delta = data[point * dimension + feature]
                    - initial_centroids[cluster * dimension + feature];
                distance += delta * delta;
            }
            if (distance < best_distance) {
                best_cluster = cluster;
                best_distance = distance;
            }
        }
        staged[point] = (double)best_cluster;
        ++counts[best_cluster];
        for (size_t feature = 0; feature < dimension; ++feature)
            sums[best_cluster * dimension + feature] += data[point * dimension + feature];
    }

    for (size_t cluster = 0; cluster < cluster_count; ++cluster) {
        if (counts[cluster] == 0) return -1;
        for (size_t feature = 0; feature < dimension; ++feature) {
            const size_t output_index = point_count + cluster * dimension + feature;
            staged[output_index] = (double)sums[cluster * dimension + feature]
                / (double)counts[cluster];
        }
    }

    const size_t output_length = point_count + cluster_count * dimension;
    if (output == NULL || output_capacity < output_length) return -2;
    for (size_t index = 0; index < output_length; ++index) output[index] = staged[index];
    return (int64_t)output_length;
}
