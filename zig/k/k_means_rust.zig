const U53_MAX: i64 = 9_007_199_254_740_991;
const U53_DENOMINATOR: f64 = 9_007_199_254_740_992.0;

export fn k_means_rust(input: ?[*]const i64, length: usize) i64 {
    const values = input orelse return -1;
    if (length != 10 or values[0] != 4) return -1;
    const max_iter = values[1];
    if (max_iter < 1 or max_iter > 16) return -1;
    const draw0 = values[2];
    const draw1 = values[4];
    if (values[3] != 0 or values[5] != 0 or draw0 < 0 or draw0 > U53_MAX or
        draw1 < 0 or draw1 > U53_MAX or draw0 == draw1) return -1;

    var points = [_]f64{0.0} ** 4;
    for (0..4) |index| {
        const coordinate = values[index + 6];
        if (coordinate < -16 or coordinate > 16 or
            (index > 0 and values[index + 5] >= coordinate)) return -1;
        points[index] = @floatFromInt(coordinate);
    }
    if (values[7] >= 0 or values[8] <= 1) return -1;

    var centers = [2][2]f64{
        .{ @as(f64, @floatFromInt(draw0)) / U53_DENOMINATOR, 0.0 },
        .{ @as(f64, @floatFromInt(draw1)) / U53_DENOMINATOR, 0.0 },
    };
    var labels = [_]i64{0} ** 4;
    for (0..@intCast(max_iter)) |_| {
        var sums = [_][2]f64{.{ 0.0, 0.0 }} ** 2;
        var counts = [_]usize{0} ** 2;
        for (0..4) |index| {
            const dx0 = points[index] - centers[0][0];
            const dy0 = -centers[0][1];
            const dx1 = points[index] - centers[1][0];
            const dy1 = -centers[1][1];
            const distance0 = dx0 * dx0 + dy0 * dy0;
            const distance1 = dx1 * dx1 + dy1 * dy1;
            const cluster: usize = if (distance1 < distance0) 1 else 0;
            labels[index] = @intCast(cluster);
            sums[cluster][0] += points[index];
            sums[cluster][1] += 0.0;
            counts[cluster] += 1;
        }
        if (counts[0] == 0 or counts[1] == 0) return -1;
        for (0..2) |cluster| {
            centers[cluster][0] = sums[cluster][0] / @as(f64, @floatFromInt(counts[cluster]));
            centers[cluster][1] = sums[cluster][1] / @as(f64, @floatFromInt(counts[cluster]));
        }
    }

    var packed: i64 = 0;
    for (0..4) |index| packed |= labels[index] << @intCast(index);
    return packed;
}
