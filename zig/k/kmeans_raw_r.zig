const INVALID_RESULT: f64 = -1.0e300;
const MAX_INPUT_LENGTH: usize = 144;
const MAX_ROWS: usize = 32;
const MAX_DIMENSIONS: usize = 4;
const MAX_CLUSTERS: usize = 8;
const MAX_ITERATIONS: usize = 64;

export fn kmeans_raw_r(input: ?[*]const i64, length: usize) f64 {
    const values = input orelse return INVALID_RESULT;
    if (length < 12 or length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    const rows_value = values[0];
    const dimensions_value = values[1];
    const clusters_value = values[2];
    const iteration_limit_value = values[3];
    if (rows_value < 2 or rows_value > MAX_ROWS or dimensions_value < 2 or dimensions_value > MAX_DIMENSIONS or
        clusters_value < 1 or clusters_value > MAX_CLUSTERS or clusters_value > @divTrunc(rows_value, 2) or
        iteration_limit_value < 1 or iteration_limit_value > MAX_ITERATIONS) return INVALID_RESULT;

    const rows: usize = @intCast(rows_value);
    const dimensions: usize = @intCast(dimensions_value);
    const clusters: usize = @intCast(clusters_value);
    const iteration_limit: usize = @intCast(iteration_limit_value);
    const data_count = rows * dimensions;
    const data_start = 4 + clusters;
    const selector_start = data_start + data_count;
    if (length != selector_start + 3) return INVALID_RESULT;

    var data = [_]f64{0.0} ** (MAX_ROWS * MAX_DIMENSIONS);
    for (0..clusters) |cluster| {
        const initial_row = values[4 + cluster];
        if (initial_row < 0 or initial_row >= rows_value) return INVALID_RESULT;
        for (0..cluster) |earlier| {
            if (values[4 + earlier] == initial_row) return INVALID_RESULT;
        }
    }
    for (0..data_count) |index| {
        const coordinate = values[data_start + index];
        if (coordinate < -64 or coordinate > 64) return INVALID_RESULT;
        data[index] = @floatFromInt(coordinate);
    }

    const field = values[selector_start];
    const arg0 = values[selector_start + 1];
    const arg1 = values[selector_start + 2];
    if (field < 0 or field > 2) return INVALID_RESULT;
    if (field == 0 and (arg0 < 0 or arg0 >= clusters_value or arg1 < 0 or arg1 >= dimensions_value))
        return INVALID_RESULT;
    if (field == 1 and (arg0 < 0 or arg0 >= rows_value or arg1 < 0 or arg1 >= clusters_value))
        return INVALID_RESULT;
    if (field == 2 and (arg0 < 0 or arg0 >= rows_value or arg1 != 0)) return INVALID_RESULT;

    var centers = [_]f64{0.0} ** (MAX_CLUSTERS * MAX_DIMENSIONS);
    for (0..clusters) |cluster| {
        const initial_row: usize = @intCast(values[4 + cluster]);
        for (0..dimensions) |dimension| {
            centers[cluster * dimensions + dimension] = data[initial_row * dimensions + dimension];
        }
    }

    var distances = [_][MAX_CLUSTERS]f64{[_]f64{0.0} ** MAX_CLUSTERS} ** MAX_ROWS;
    var assignments = [_]usize{0} ** MAX_ROWS;
    var stable = false;
    for (0..iteration_limit) |_| {
        var member_counts = [_]usize{0} ** MAX_CLUSTERS;
        for (0..rows) |row| {
            var best_cluster: usize = 0;
            for (0..clusters) |cluster| {
                var squared_distance: f64 = 0.0;
                for (0..dimensions) |dimension| {
                    const difference = data[row * dimensions + dimension] - centers[cluster * dimensions + dimension];
                    squared_distance += difference * difference;
                }
                distances[row][cluster] = @sqrt(squared_distance);
                if (cluster > 0 and distances[row][cluster] < distances[row][best_cluster]) best_cluster = cluster;
            }
            assignments[row] = best_cluster;
            member_counts[best_cluster] += 1;
        }
        for (0..clusters) |cluster| {
            if (member_counts[cluster] < 2) return INVALID_RESULT;
        }

        var updated = [_]f64{0.0} ** (MAX_CLUSTERS * MAX_DIMENSIONS);
        for (0..rows) |row| {
            const cluster = assignments[row];
            for (0..dimensions) |dimension| {
                updated[cluster * dimensions + dimension] += data[row * dimensions + dimension];
            }
        }
        stable = true;
        for (0..clusters) |cluster| {
            for (0..dimensions) |dimension| {
                const index = cluster * dimensions + dimension;
                updated[index] /= @floatFromInt(member_counts[cluster]);
                if (updated[index] != centers[index]) stable = false;
            }
        }
        @memcpy(centers[0 .. clusters * dimensions], updated[0 .. clusters * dimensions]);
        if (stable) break;
    }
    if (!stable) return INVALID_RESULT;

    const index0: usize = @intCast(arg0);
    const index1: usize = @intCast(arg1);
    if (field == 0) return centers[index0 * dimensions + index1];
    if (field == 1) return distances[index0][index1];
    return @floatFromInt(assignments[index0]);
}
