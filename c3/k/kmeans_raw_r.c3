module kmeans_raw_r;

const double INVALID_RESULT = -1.0e300;
const usz MAX_INPUT_LENGTH = 144;
const usz MAX_ROWS = 32;
const usz MAX_DIMENSIONS = 4;
const usz MAX_CLUSTERS = 8;
const usz MAX_ITERATIONS = 64;
extern fn double sqrt(double value);

fn double kmeans_raw_r(long* values, usz length) @export("kmeans_raw_r") {
    if (values == null || length < 12 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    long rows_value = values[0];
    long dimensions_value = values[1];
    long clusters_value = values[2];
    long iteration_limit_value = values[3];
    if (rows_value < 2 || rows_value > (long)MAX_ROWS || dimensions_value < 2 || dimensions_value > (long)MAX_DIMENSIONS ||
        clusters_value < 1 || clusters_value > (long)MAX_CLUSTERS || clusters_value > rows_value / 2 ||
        iteration_limit_value < 1 || iteration_limit_value > (long)MAX_ITERATIONS) return INVALID_RESULT;

    usz rows = (usz)rows_value;
    usz dimensions = (usz)dimensions_value;
    usz clusters = (usz)clusters_value;
    usz iteration_limit = (usz)iteration_limit_value;
    usz data_count = rows * dimensions;
    usz data_start = 4 + clusters;
    usz selector_start = data_start + data_count;
    if (length != selector_start + 3) return INVALID_RESULT;

    double[128] data = zeroed;
    for (usz cluster = 0; cluster < clusters; cluster++) {
        long initial_row = values[4 + cluster];
        if (initial_row < 0 || initial_row >= rows_value) return INVALID_RESULT;
        for (usz earlier = 0; earlier < cluster; earlier++)
            if (values[4 + earlier] == initial_row) return INVALID_RESULT;
    }
    for (usz index = 0; index < data_count; index++) {
        long coordinate = values[data_start + index];
        if (coordinate < -64 || coordinate > 64) return INVALID_RESULT;
        data[index] = (double)coordinate;
    }

    long field = values[selector_start];
    long arg0 = values[selector_start + 1];
    long arg1 = values[selector_start + 2];
    if (field < 0 || field > 2) return INVALID_RESULT;
    if (field == 0 && (arg0 < 0 || arg0 >= clusters_value || arg1 < 0 || arg1 >= dimensions_value)) return INVALID_RESULT;
    if (field == 1 && (arg0 < 0 || arg0 >= rows_value || arg1 < 0 || arg1 >= clusters_value)) return INVALID_RESULT;
    if (field == 2 && (arg0 < 0 || arg0 >= rows_value || arg1 != 0)) return INVALID_RESULT;

    double[32] centers = zeroed;
    for (usz cluster = 0; cluster < clusters; cluster++) {
        usz initial_row = (usz)values[4 + cluster];
        for (usz dimension = 0; dimension < dimensions; dimension++)
            centers[cluster * dimensions + dimension] = data[initial_row * dimensions + dimension];
    }

    double[256] distances = zeroed;
    usz[32] assignments = zeroed;
    bool stable = false;
    for (usz iteration = 0; iteration < iteration_limit; iteration++) {
        usz[8] member_counts = zeroed;
        for (usz row = 0; row < rows; row++) {
            usz best_cluster = 0;
            for (usz cluster = 0; cluster < clusters; cluster++) {
                double squared_distance = 0.0;
                for (usz dimension = 0; dimension < dimensions; dimension++) {
                    double difference = data[row * dimensions + dimension] - centers[cluster * dimensions + dimension];
                    squared_distance += difference * difference;
                }
                distances[row * clusters + cluster] = sqrt(squared_distance);
                if (cluster > 0 && distances[row * clusters + cluster] < distances[row * clusters + best_cluster])
                    best_cluster = cluster;
            }
            assignments[row] = best_cluster;
            member_counts[best_cluster]++;
        }
        for (usz cluster = 0; cluster < clusters; cluster++)
            if (member_counts[cluster] < 2) return INVALID_RESULT;

        double[32] updated = zeroed;
        for (usz row = 0; row < rows; row++) {
            usz cluster = assignments[row];
            for (usz dimension = 0; dimension < dimensions; dimension++)
                updated[cluster * dimensions + dimension] += data[row * dimensions + dimension];
        }
        stable = true;
        for (usz cluster = 0; cluster < clusters; cluster++) {
            for (usz dimension = 0; dimension < dimensions; dimension++) {
                usz index = cluster * dimensions + dimension;
                updated[index] /= (double)member_counts[cluster];
                if (updated[index] != centers[index]) stable = false;
            }
        }
        for (usz index = 0; index < clusters * dimensions; index++) centers[index] = updated[index];
        if (stable) break;
    }
    if (!stable) return INVALID_RESULT;

    if (field == 0) return centers[(usz)arg0 * dimensions + (usz)arg1];
    if (field == 1) return distances[(usz)arg0 * clusters + (usz)arg1];
    return (double)assignments[(usz)arg0];
}
