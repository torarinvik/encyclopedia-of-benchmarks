#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr double INVALID_RESULT = -1.0e300;
constexpr std::size_t MAX_INPUT_LENGTH = 144;
constexpr std::size_t MAX_ROWS = 32;
constexpr std::size_t MAX_DIMENSIONS = 4;
constexpr std::size_t MAX_CLUSTERS = 8;
constexpr std::size_t MAX_ITERATIONS = 64;
}

extern "C" double kmeans_raw_r(const std::int64_t *values, std::size_t length) noexcept
{
    if (values == nullptr || length < 12 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    const std::int64_t rows_value = values[0];
    const std::int64_t dimensions_value = values[1];
    const std::int64_t clusters_value = values[2];
    const std::int64_t iteration_limit_value = values[3];
    if (rows_value < 2 || rows_value > static_cast<std::int64_t>(MAX_ROWS) ||
        dimensions_value < 2 || dimensions_value > static_cast<std::int64_t>(MAX_DIMENSIONS) ||
        clusters_value < 1 || clusters_value > static_cast<std::int64_t>(MAX_CLUSTERS) ||
        clusters_value > rows_value / 2 || iteration_limit_value < 1 ||
        iteration_limit_value > static_cast<std::int64_t>(MAX_ITERATIONS))
        return INVALID_RESULT;

    const std::size_t rows = static_cast<std::size_t>(rows_value);
    const std::size_t dimensions = static_cast<std::size_t>(dimensions_value);
    const std::size_t clusters = static_cast<std::size_t>(clusters_value);
    const std::size_t iteration_limit = static_cast<std::size_t>(iteration_limit_value);
    const std::size_t data_count = rows * dimensions;
    const std::size_t data_start = 4 + clusters;
    const std::size_t selector_start = data_start + data_count;
    if (length != selector_start + 3) return INVALID_RESULT;

    double data[MAX_ROWS * MAX_DIMENSIONS]{};
    for (std::size_t cluster = 0; cluster < clusters; ++cluster) {
        const std::int64_t initial_row = values[4 + cluster];
        if (initial_row < 0 || initial_row >= rows_value) return INVALID_RESULT;
        for (std::size_t earlier = 0; earlier < cluster; ++earlier)
            if (values[4 + earlier] == initial_row) return INVALID_RESULT;
    }
    for (std::size_t index = 0; index < data_count; ++index) {
        const std::int64_t coordinate = values[data_start + index];
        if (coordinate < -64 || coordinate > 64) return INVALID_RESULT;
        data[index] = static_cast<double>(coordinate);
    }

    const std::int64_t field = values[selector_start];
    const std::int64_t arg0 = values[selector_start + 1];
    const std::int64_t arg1 = values[selector_start + 2];
    if (field < 0 || field > 2) return INVALID_RESULT;
    if (field == 0 && (arg0 < 0 || arg0 >= clusters_value || arg1 < 0 || arg1 >= dimensions_value))
        return INVALID_RESULT;
    if (field == 1 && (arg0 < 0 || arg0 >= rows_value || arg1 < 0 || arg1 >= clusters_value))
        return INVALID_RESULT;
    if (field == 2 && (arg0 < 0 || arg0 >= rows_value || arg1 != 0)) return INVALID_RESULT;

    double centers[MAX_CLUSTERS * MAX_DIMENSIONS]{};
    for (std::size_t cluster = 0; cluster < clusters; ++cluster) {
        const std::size_t initial_row = static_cast<std::size_t>(values[4 + cluster]);
        for (std::size_t dimension = 0; dimension < dimensions; ++dimension)
            centers[cluster * dimensions + dimension] = data[initial_row * dimensions + dimension];
    }

    double distances[MAX_ROWS * MAX_CLUSTERS]{};
    std::size_t assignments[MAX_ROWS]{};
    bool stable = false;
    for (std::size_t iteration = 0; iteration < iteration_limit; ++iteration) {
        std::size_t member_counts[MAX_CLUSTERS]{};
        for (std::size_t row = 0; row < rows; ++row) {
            std::size_t best_cluster = 0;
            for (std::size_t cluster = 0; cluster < clusters; ++cluster) {
                double squared_distance = 0.0;
                for (std::size_t dimension = 0; dimension < dimensions; ++dimension) {
                    const double difference = data[row * dimensions + dimension] - centers[cluster * dimensions + dimension];
                    squared_distance += difference * difference;
                }
                distances[row * clusters + cluster] = std::sqrt(squared_distance);
                if (cluster > 0 && distances[row * clusters + cluster] < distances[row * clusters + best_cluster])
                    best_cluster = cluster;
            }
            assignments[row] = best_cluster;
            ++member_counts[best_cluster];
        }
        for (std::size_t cluster = 0; cluster < clusters; ++cluster)
            if (member_counts[cluster] < 2) return INVALID_RESULT;

        double updated[MAX_CLUSTERS * MAX_DIMENSIONS]{};
        for (std::size_t row = 0; row < rows; ++row) {
            const std::size_t cluster = assignments[row];
            for (std::size_t dimension = 0; dimension < dimensions; ++dimension)
                updated[cluster * dimensions + dimension] += data[row * dimensions + dimension];
        }
        stable = true;
        for (std::size_t cluster = 0; cluster < clusters; ++cluster) {
            for (std::size_t dimension = 0; dimension < dimensions; ++dimension) {
                const std::size_t index = cluster * dimensions + dimension;
                updated[index] /= static_cast<double>(member_counts[cluster]);
                if (updated[index] != centers[index]) stable = false;
            }
        }
        for (std::size_t index = 0; index < clusters * dimensions; ++index) centers[index] = updated[index];
        if (stable) break;
    }
    if (!stable) return INVALID_RESULT;

    if (field == 0) return centers[static_cast<std::size_t>(arg0) * dimensions + static_cast<std::size_t>(arg1)];
    if (field == 1) return distances[static_cast<std::size_t>(arg0) * clusters + static_cast<std::size_t>(arg1)];
    return static_cast<double>(assignments[static_cast<std::size_t>(arg0)]);
}
