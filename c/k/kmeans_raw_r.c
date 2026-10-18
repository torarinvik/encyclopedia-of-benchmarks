#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT (-1e300)
#define MAX_INPUT_LENGTH 144
#define MAX_ROWS 32
#define MAX_DIMENSIONS 4
#define MAX_CLUSTERS 8
#define MAX_ITERATIONS 64

double kmeans_raw_r(const int64_t *values, size_t length)
{
    if (values == NULL || length < 12 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    const int64_t rows_value = values[0];
    const int64_t dimensions_value = values[1];
    const int64_t clusters_value = values[2];
    const int64_t iteration_limit_value = values[3];
    if (rows_value < 2 || rows_value > MAX_ROWS || dimensions_value < 2 || dimensions_value > MAX_DIMENSIONS ||
        clusters_value < 1 || clusters_value > MAX_CLUSTERS || clusters_value > rows_value / 2 ||
        iteration_limit_value < 1 || iteration_limit_value > MAX_ITERATIONS)
        return INVALID_RESULT;

    const size_t rows = (size_t)rows_value;
    const size_t dimensions = (size_t)dimensions_value;
    const size_t clusters = (size_t)clusters_value;
    const size_t iteration_limit = (size_t)iteration_limit_value;
    const size_t data_count = rows * dimensions;
    const size_t data_start = 4 + clusters;
    const size_t selector_start = data_start + data_count;
    if (length != selector_start + 3) return INVALID_RESULT;

    double data[MAX_ROWS * MAX_DIMENSIONS] = {0};
    for (size_t cluster = 0; cluster < clusters; ++cluster) {
        const int64_t initial_row = values[4 + cluster];
        if (initial_row < 0 || (uint64_t)initial_row >= rows_value) return INVALID_RESULT;
        for (size_t earlier = 0; earlier < cluster; ++earlier)
            if (values[4 + earlier] == initial_row) return INVALID_RESULT;
    }
    for (size_t index = 0; index < data_count; ++index) {
        const int64_t coordinate = values[data_start + index];
        if (coordinate < -64 || coordinate > 64) return INVALID_RESULT;
        data[index] = (double)coordinate;
    }

    const int64_t field = values[selector_start];
    const int64_t arg0 = values[selector_start + 1];
    const int64_t arg1 = values[selector_start + 2];
    if (field < 0 || field > 2) return INVALID_RESULT;
    if (field == 0 && (arg0 < 0 || (uint64_t)arg0 >= clusters || arg1 < 0 || (uint64_t)arg1 >= dimensions))
        return INVALID_RESULT;
    if (field == 1 && (arg0 < 0 || (uint64_t)arg0 >= rows || arg1 < 0 || (uint64_t)arg1 >= clusters))
        return INVALID_RESULT;
    if (field == 2 && (arg0 < 0 || (uint64_t)arg0 >= rows || arg1 != 0)) return INVALID_RESULT;

    double centers[MAX_CLUSTERS * MAX_DIMENSIONS] = {0};
    for (size_t cluster = 0; cluster < clusters; ++cluster) {
        const size_t initial_row = (size_t)values[4 + cluster];
        for (size_t dimension = 0; dimension < dimensions; ++dimension)
            centers[cluster * dimensions + dimension] = data[initial_row * dimensions + dimension];
    }

    double distances[MAX_ROWS * MAX_CLUSTERS] = {0};
    size_t assignments[MAX_ROWS] = {0};
    int stable = 0;
    for (size_t iteration = 0; iteration < iteration_limit; ++iteration) {
        size_t member_counts[MAX_CLUSTERS] = {0};
        for (size_t row = 0; row < rows; ++row) {
            size_t best_cluster = 0;
            for (size_t cluster = 0; cluster < clusters; ++cluster) {
                double squared_distance = 0.0;
                for (size_t dimension = 0; dimension < dimensions; ++dimension) {
                    const double difference = data[row * dimensions + dimension] - centers[cluster * dimensions + dimension];
                    squared_distance += difference * difference;
                }
                distances[row * clusters + cluster] = sqrt(squared_distance);
                if (cluster > 0 && distances[row * clusters + cluster] < distances[row * clusters + best_cluster])
                    best_cluster = cluster;
            }
            assignments[row] = best_cluster;
            ++member_counts[best_cluster];
        }
        for (size_t cluster = 0; cluster < clusters; ++cluster)
            if (member_counts[cluster] < 2) return INVALID_RESULT;

        double updated[MAX_CLUSTERS * MAX_DIMENSIONS] = {0};
        for (size_t row = 0; row < rows; ++row) {
            const size_t cluster = assignments[row];
            for (size_t dimension = 0; dimension < dimensions; ++dimension)
                updated[cluster * dimensions + dimension] += data[row * dimensions + dimension];
        }
        stable = 1;
        for (size_t cluster = 0; cluster < clusters; ++cluster) {
            for (size_t dimension = 0; dimension < dimensions; ++dimension) {
                const size_t index = cluster * dimensions + dimension;
                updated[index] /= (double)member_counts[cluster];
                if (updated[index] != centers[index]) stable = 0;
            }
        }
        for (size_t index = 0; index < clusters * dimensions; ++index) centers[index] = updated[index];
        if (stable) break;
    }
    if (!stable) return INVALID_RESULT;

    if (field == 0) return centers[(size_t)arg0 * dimensions + (size_t)arg1];
    if (field == 1) return distances[(size_t)arg0 * clusters + (size_t)arg1];
    return (double)assignments[(size_t)arg0];
}
