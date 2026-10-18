const MAX_MOVES: usize = 64;
const CENTER_SCALE: f64 = 256.0;
const CENTER_BIAS: i64 = 4097;
const CENTER_BASE: i64 = 8194;

export fn k_means_clustering_c(input: ?[*]const i64, length: usize) i64 {
    const values = input orelse return -1;
    if (length < 1 or length > 18) return -1;
    if (values[0] < 3 or values[0] > 8) return -1;
    const n: usize = @intCast(values[0]);
    if (length != 1 + 2 * n) return -1;

    var labels = [_]i64{0} ** 8;
    var has_zero = false;
    var has_one = false;
    for (0..n) |index| {
        const label = values[index + 1];
        const coordinate = values[1 + n + index];
        if (label != 0 and label != 1) return -1;
        labels[index] = label;
        has_zero = has_zero or label == 0;
        has_one = has_one or label == 1;
        if (coordinate < -16 or coordinate > 16 or
            (index > 0 and values[n + index] >= coordinate)) return -1;
    }
    if (!has_zero or !has_one) return -1;

    for (0..MAX_MOVES) |_| {
        var sums = [_]f64{0.0} ** 2;
        var counts = [_]usize{0} ** 2;
        for (0..n) |index| {
            const cluster: usize = @intCast(labels[index]);
            sums[cluster] += @floatFromInt(values[1 + n + index]);
            counts[cluster] += 1;
        }
        if (counts[0] == 0 or counts[1] == 0) return -1;
        const centers = [2]f64{
            sums[0] / @as(f64, @floatFromInt(counts[0])),
            sums[1] / @as(f64, @floatFromInt(counts[1])),
        };

        var next_labels = [_]i64{0} ** 8;
        var changed: usize = 0;
        for (0..n) |index| {
            const point: f64 = @floatFromInt(values[1 + n + index]);
            const d0 = point - centers[0];
            const d1 = point - centers[1];
            const cluster: i64 = if (d1 * d1 < d0 * d0) 1 else 0;
            next_labels[index] = cluster;
            if (next_labels[index] != labels[index]) changed += 1;
        }
        labels = next_labels;
        if (changed == 0) {
            const code0 = @as(i64, @intFromFloat(centers[0] * CENTER_SCALE)) + CENTER_BIAS;
            const code1 = @as(i64, @intFromFloat(centers[1] * CENTER_SCALE)) + CENTER_BIAS;
            if (code0 < 1 or code0 > 8193 or code1 < 1 or code1 > 8193) return -1;
            return code0 * CENTER_BASE + code1;
        }
    }
    return -2;
}
