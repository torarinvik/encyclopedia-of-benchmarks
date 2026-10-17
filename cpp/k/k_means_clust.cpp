#include <cstddef>
#include <cstdint>

namespace {
bool bounded_integer(double value, std::int64_t minimum, std::int64_t maximum,
                     std::int64_t& result) noexcept {
    if (value != value || value < static_cast<double>(minimum) ||
        value > static_cast<double>(maximum)) return false;
    const auto integer = static_cast<std::int64_t>(value);
    if (static_cast<double>(integer) != value) return false;
    result = integer;
    return true;
}
}

extern "C" std::int64_t k_means_clust(const double* input, std::size_t input_length,
                                      double* output, std::size_t output_capacity) noexcept {
    constexpr std::size_t max_parseable_input_length = 84;
    constexpr std::size_t max_point_count = 16;
    constexpr std::size_t max_dimension = 4;
    constexpr std::size_t max_cluster_count = 4;
    constexpr std::size_t max_output_elements = 32;
    if (input == nullptr || input_length < 3 || input_length > max_parseable_input_length) return -1;

    std::int64_t point_count_value, dimension_value, cluster_count_value;
    if (!bounded_integer(input[0], 1, static_cast<std::int64_t>(max_point_count), point_count_value) ||
        !bounded_integer(input[1], 1, static_cast<std::int64_t>(max_dimension), dimension_value) ||
        !bounded_integer(input[2], 1, static_cast<std::int64_t>(max_cluster_count), cluster_count_value)) return -1;
    if (cluster_count_value > point_count_value) return -1;

    const auto point_count = static_cast<std::size_t>(point_count_value);
    const auto dimension = static_cast<std::size_t>(dimension_value);
    const auto cluster_count = static_cast<std::size_t>(cluster_count_value);
    constexpr std::size_t data_start = 3;
    const std::size_t centroid_start = data_start + point_count * dimension;
    const std::size_t expected_length = centroid_start + cluster_count * dimension;
    if (input_length != expected_length) return -1;

    std::int64_t data[max_point_count * max_dimension]{};
    std::int64_t initial_centroids[max_cluster_count * max_dimension]{};
    for (std::size_t index = 0; index < point_count * dimension; ++index) {
        if (!bounded_integer(input[data_start + index], -16, 16, data[index])) return -1;
    }
    for (std::size_t index = 0; index < cluster_count * dimension; ++index) {
        if (!bounded_integer(input[centroid_start + index], -16, 16, initial_centroids[index])) return -1;
    }

    double staged[max_output_elements]{};
    std::int64_t counts[max_cluster_count]{};
    std::int64_t sums[max_cluster_count * max_dimension]{};
    for (std::size_t point = 0; point < point_count; ++point) {
        std::size_t best_cluster = 0;
        std::int64_t best_distance = 0;
        for (std::size_t feature = 0; feature < dimension; ++feature) {
            const std::int64_t delta = data[point * dimension + feature] - initial_centroids[feature];
            best_distance += delta * delta;
        }
        for (std::size_t cluster = 1; cluster < cluster_count; ++cluster) {
            std::int64_t distance = 0;
            for (std::size_t feature = 0; feature < dimension; ++feature) {
                const std::int64_t delta = data[point * dimension + feature]
                    - initial_centroids[cluster * dimension + feature];
                distance += delta * delta;
            }
            if (distance < best_distance) {
                best_cluster = cluster;
                best_distance = distance;
            }
        }
        staged[point] = static_cast<double>(best_cluster);
        ++counts[best_cluster];
        for (std::size_t feature = 0; feature < dimension; ++feature)
            sums[best_cluster * dimension + feature] += data[point * dimension + feature];
    }

    for (std::size_t cluster = 0; cluster < cluster_count; ++cluster) {
        if (counts[cluster] == 0) return -1;
        for (std::size_t feature = 0; feature < dimension; ++feature) {
            const std::size_t output_index = point_count + cluster * dimension + feature;
            staged[output_index] = static_cast<double>(sums[cluster * dimension + feature])
                / static_cast<double>(counts[cluster]);
        }
    }

    const std::size_t output_length = point_count + cluster_count * dimension;
    if (output == nullptr || output_capacity < output_length) return -2;
    for (std::size_t index = 0; index < output_length; ++index) output[index] = staged[index];
    return static_cast<std::int64_t>(output_length);
}
