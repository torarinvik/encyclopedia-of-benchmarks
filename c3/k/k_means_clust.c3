module k_means_clust;

const usz MAX_PARSEABLE_INPUT_LENGTH = 84;
const usz MAX_POINT_COUNT = 16;
const usz MAX_DIMENSION = 4;
const usz MAX_CLUSTER_COUNT = 4;
const usz MAX_OUTPUT_ELEMENTS = 32;

bool bounded_integer(double value, long minimum, long maximum, long* result) {
    if (value != value || value < (double)minimum || value > (double)maximum) return false;
    long integer = (long)value;
    if ((double)integer != value) return false;
    *result = integer;
    return true;
}

fn long k_means_clust(double* input, usz input_length, double* output, usz output_capacity)
    @export("k_means_clust") {
    if (input == null || input_length < 3 || input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1L;

    long point_count_value, dimension_value, cluster_count_value;
    if (!bounded_integer(input[0], 1, (long)MAX_POINT_COUNT, &point_count_value) ||
        !bounded_integer(input[1], 1, (long)MAX_DIMENSION, &dimension_value) ||
        !bounded_integer(input[2], 1, (long)MAX_CLUSTER_COUNT, &cluster_count_value)) return -1L;
    if (cluster_count_value > point_count_value) return -1L;

    usz point_count = (usz)point_count_value;
    usz dimension = (usz)dimension_value;
    usz cluster_count = (usz)cluster_count_value;
    usz data_start = 3;
    usz centroid_start = data_start + point_count * dimension;
    usz expected_length = centroid_start + cluster_count * dimension;
    if (input_length != expected_length) return -1L;

    long[MAX_POINT_COUNT * MAX_DIMENSION] data = zeroed;
    long[MAX_CLUSTER_COUNT * MAX_DIMENSION] initial_centroids = zeroed;
    for (usz index = 0; index < point_count * dimension; index++) {
        if (!bounded_integer(input[data_start + index], -16, 16, &data[index])) return -1L;
    }
    for (usz index = 0; index < cluster_count * dimension; index++) {
        if (!bounded_integer(input[centroid_start + index], -16, 16,
                             &initial_centroids[index])) return -1L;
    }

    double[MAX_OUTPUT_ELEMENTS] staged = zeroed;
    long[MAX_CLUSTER_COUNT] counts = zeroed;
    long[MAX_CLUSTER_COUNT * MAX_DIMENSION] sums = zeroed;
    for (usz point = 0; point < point_count; point++) {
        usz best_cluster = 0;
        long best_distance = 0;
        for (usz feature = 0; feature < dimension; feature++) {
            long delta = data[point * dimension + feature] - initial_centroids[feature];
            best_distance += delta * delta;
        }
        for (usz cluster = 1; cluster < cluster_count; cluster++) {
            long distance = 0;
            for (usz feature = 0; feature < dimension; feature++) {
                long delta = data[point * dimension + feature]
                    - initial_centroids[cluster * dimension + feature];
                distance += delta * delta;
            }
            if (distance < best_distance) {
                best_cluster = cluster;
                best_distance = distance;
            }
        }
        staged[point] = (double)best_cluster;
        counts[best_cluster]++;
        for (usz feature = 0; feature < dimension; feature++)
            sums[best_cluster * dimension + feature] += data[point * dimension + feature];
    }

    for (usz cluster = 0; cluster < cluster_count; cluster++) {
        if (counts[cluster] == 0) return -1L;
        for (usz feature = 0; feature < dimension; feature++) {
            usz output_index = point_count + cluster * dimension + feature;
            staged[output_index] = (double)sums[cluster * dimension + feature]
                / (double)counts[cluster];
        }
    }

    usz output_length = point_count + cluster_count * dimension;
    if (output == null || output_capacity < output_length) return -2L;
    for (usz index = 0; index < output_length; index++) output[index] = staged[index];
    return (long)output_length;
}
