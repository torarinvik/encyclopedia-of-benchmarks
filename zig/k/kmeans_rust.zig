const MAX_MOVES: usize = 256;

export fn kmeans_rust(input: ?[*]const i64, length: usize) i64 {
    const values = input orelse return -1;
    if (length < 2 or length > 10) return -1;
    if (values[0] < 2 or values[0] > 8) return -1;
    const n: usize = @intCast(values[0]);
    if (length != n + 1) return -1;

    var points = [_]f64{0.0} ** 8;
    for (0..n) |index| {
        const coordinate = values[index + 1];
        if (coordinate < -16 or coordinate > 16 or (index > 0 and values[index] >= coordinate)) return -1;
        points[index] = @floatFromInt(coordinate);
    }

    var centers = [2]f64{ points[0], points[n / 2] };
    var labels = [_]i64{0} ** 8;
    for (0..n) |index| {
        const d0 = points[index] - centers[0];
        const d1 = points[index] - centers[1];
        if (d1 * d1 < d0 * d0) labels[index] = 1;
    }

    for (0..MAX_MOVES) |_| {
        var sums = [_]f64{0.0} ** 2;
        var counts = [_]usize{0} ** 2;
        for (0..n) |index| {
            const cluster: usize = @intCast(labels[index]);
            sums[cluster] += points[index];
            counts[cluster] += 1;
        }
        if (counts[0] == 0 or counts[1] == 0) return -1;
        centers[0] = sums[0] / @as(f64, @floatFromInt(counts[0]));
        centers[1] = sums[1] / @as(f64, @floatFromInt(counts[1]));

        var next_labels = [_]i64{0} ** 8;
        var unchanged = true;
        for (0..n) |index| {
            const d0 = points[index] - centers[0];
            const d1 = points[index] - centers[1];
            if (d1 * d1 < d0 * d0) next_labels[index] = 1;
            if (next_labels[index] != labels[index]) unchanged = false;
        }
        if (unchanged) {
            var packed: i64 = 0;
            for (0..n) |index| packed |= next_labels[index] << @intCast(index);
            return packed;
        }
        labels = next_labels;
    }
    return -2;
}
