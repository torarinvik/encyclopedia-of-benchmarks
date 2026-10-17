const std = @import("std");
const MAX_INPUT_LENGTH: usize = 84;

fn exactInteger(value: f64, minimum: f64, maximum: f64) bool {
    return std.math.isFinite(value) and @trunc(value) == value and value >= minimum and value <= maximum;
}

export fn k_means_clust(input: ?[*]const f64, input_length: usize, output: ?[*]f64, capacity: usize) i64 {
    const values = input orelse return -1;
    if (input_length < 3 or input_length > MAX_INPUT_LENGTH) return -1;
    if (!exactInteger(values[0], 1, 16) or !exactInteger(values[1], 1, 4) or !exactInteger(values[2], 1, 4)) return -1;
    const point_count: usize = @intFromFloat(values[0]);
    const dimension: usize = @intFromFloat(values[1]);
    const cluster_count: usize = @intFromFloat(values[2]);
    if (cluster_count > point_count) return -1;
    const data_start: usize = 3;
    const centroid_start = data_start + point_count * dimension;
    const expected_length = centroid_start + cluster_count * dimension;
    if (input_length != expected_length) return -1;
    for (data_start..expected_length) |i| if (!exactInteger(values[i], -16, 16)) return -1;

    var assignments = [_]usize{0} ** 16;
    var counts = [_]usize{0} ** 4;
    var sums = [_][4]i64{[_]i64{0} ** 4} ** 4;
    for (0..point_count) |point| {
        var best_cluster: usize = 0;
        var best_distance: i64 = 0;
        for (0..dimension) |feature| {
            const value: i64 = @intFromFloat(values[data_start + point * dimension + feature]);
            const center: i64 = @intFromFloat(values[centroid_start + feature]);
            const delta = value - center;
            best_distance += delta * delta;
        }
        for (1..cluster_count) |cluster| {
            var distance: i64 = 0;
            for (0..dimension) |feature| {
                const value: i64 = @intFromFloat(values[data_start + point * dimension + feature]);
                const center: i64 = @intFromFloat(values[centroid_start + cluster * dimension + feature]);
                const delta = value - center;
                distance += delta * delta;
            }
            if (distance < best_distance) { best_distance = distance; best_cluster = cluster; }
        }
        assignments[point] = best_cluster;
        counts[best_cluster] += 1;
        for (0..dimension) |feature| sums[best_cluster][feature] += @intFromFloat(values[data_start + point * dimension + feature]);
    }
    for (0..cluster_count) |cluster| if (counts[cluster] == 0) return -1;
    const output_length = point_count + cluster_count * dimension;
    const out = output orelse return -2;
    if (capacity < output_length) return -2;
    for (0..point_count) |point| out[point] = @floatFromInt(assignments[point]);
    for (0..cluster_count) |cluster| for (0..dimension) |feature| {
        out[point_count + cluster * dimension + feature] =
            @as(f64, @floatFromInt(sums[cluster][feature])) / @as(f64, @floatFromInt(counts[cluster]));
    };
    return @intCast(output_length);
}
