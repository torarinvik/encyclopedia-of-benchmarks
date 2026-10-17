const std = @import("std");
const MAX_POINTS: usize = 16;
const MAX_DIMENSION: usize = 3;
const MAX_INPUT_LENGTH: usize = 54;
const MARGIN: f64 = 1.0e-6;

fn distance(a: [*]const f64, b: [*]const f64, a_start: usize, b_start: usize, dimensions: usize) f64 {
    var sum: f64 = 0.0;
    for (0..dimensions) |d| { const difference = a[a_start + d] - b[b_start + d]; sum += difference * difference; }
    return std.math.pow(f64, sum, 0.5);
}
fn nearThreshold(value: f64, threshold: f64) bool { return @abs(value - threshold) < MARGIN; }

export fn mean_shift(input_opt: ?[*]const f64, length: usize, output_opt: ?[*]f64, capacity: usize) i64 {
    if (input_opt == null or length < 5 or length > MAX_INPUT_LENGTH) return -1;
    const input = input_opt.?;
    for (0..length) |i| if (input[i] != input[i]) return -1;
    const n_value = input[0]; const dimension_value = input[1]; const bandwidth = input[2];
    const iteration_value = input[3]; const tolerance = input[4];
    if (@trunc(n_value) != n_value or @trunc(dimension_value) != dimension_value or @trunc(iteration_value) != iteration_value) return -1;
    if (n_value < 1.0 or n_value > 16.0 or dimension_value < 1.0 or dimension_value > 3.0 or iteration_value < 1.0 or iteration_value > 64.0 or bandwidth < 0.5 or bandwidth > 20.0 or tolerance < 1.0e-5 or tolerance > 1.0e-2) return -1;
    const n: usize = @intFromFloat(n_value); const dimensions: usize = @intFromFloat(dimension_value); const max_iterations: usize = @intFromFloat(iteration_value);
    if (length != 5 + n * dimensions) return -1;
    var data: [MAX_POINTS * MAX_DIMENSION]f64 = @splat(0.0);
    for (0..n * dimensions) |i| { const value = input[5 + i]; if (value < -10.0 or value > 10.0) return -1; data[i] = value; }
    var candidates: [MAX_POINTS * MAX_DIMENSION]f64 = @splat(0.0);
    var next: [MAX_POINTS * MAX_DIMENSION]f64 = @splat(0.0);
    for (0..n * dimensions) |i| candidates[i] = data[i];
    for (0..max_iterations) |_| {
        for (0..n) |c| {
            var sums: [MAX_DIMENSION]f64 = @splat(0.0); var neighbors: usize = 0;
            for (0..n) |p| {
                const dist = distance(&data, &candidates, p * dimensions, c * dimensions, dimensions);
                if (nearThreshold(dist, bandwidth)) return -1;
                if (dist <= bandwidth) { neighbors += 1; for (0..dimensions) |d| sums[d] += data[p * dimensions + d]; }
            }
            for (0..dimensions) |d| next[c * dimensions + d] = if (neighbors == 0) candidates[c * dimensions + d] else sums[d] / @as(f64, @floatFromInt(neighbors));
        }
        var all_converged = true;
        for (0..n) |c| {
            const movement = distance(&candidates, &next, c * dimensions, c * dimensions, dimensions);
            if (nearThreshold(movement, tolerance)) return -1;
            if (movement >= tolerance) { all_converged = false; break; }
        }
        if (all_converged) break;
        for (0..n * dimensions) |i| candidates[i] = next[i];
    }
    var centroids: [MAX_POINTS * MAX_DIMENSION]f64 = @splat(0.0); var centroid_count: usize = 0;
    for (0..n) |c| {
        var keep = true;
        for (0..centroid_count) |e| {
            const dist = distance(&candidates, &centroids, c * dimensions, e * dimensions, dimensions);
            if (nearThreshold(dist, bandwidth)) return -1;
            if (dist < bandwidth) { keep = false; break; }
        }
        if (keep) { for (0..dimensions) |d| centroids[centroid_count * dimensions + d] = candidates[c * dimensions + d]; centroid_count += 1; }
    }
    var labels: [MAX_POINTS]f64 = @splat(0.0);
    for (0..n) |p| {
        var best_index: usize = 0; var best_distance = distance(&data, &centroids, p * dimensions, 0, dimensions);
        for (1..centroid_count) |c| {
            const dist = distance(&data, &centroids, p * dimensions, c * dimensions, dimensions);
            if (dist != best_distance and nearThreshold(dist, best_distance)) return -1;
            if (dist < best_distance) { best_index = c; best_distance = dist; }
        }
        labels[p] = @floatFromInt(best_index);
    }
    if (output_opt == null or capacity < n) return -2;
    const output = output_opt.?; for (0..n) |i| output[i] = labels[i];
    return @intCast(n);
}
