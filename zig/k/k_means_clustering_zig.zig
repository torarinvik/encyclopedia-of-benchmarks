const MAX_MOVES: usize = 64;
const CENTER_BIAS: i64 = 4097;
const CENTER_BASE: i64 = 8194;

export fn k_means_clustering_zig(input: ?[*]const i64, length: usize) i64 {
    const values = input orelse return -1;
    if (length < 2 or length > 10) return -1;
    if (values[0] < 2 or values[0] > 8) return -1;
    const point_count: usize = @intCast(values[0]);
    if (length != point_count + 1) return -1;

    var points = [_]f32{0.0} ** 8;
    for (0..point_count) |index| {
        const coordinate = values[index + 1];
        if (coordinate < -16 or coordinate > 16 or (index > 0 and values[index] >= coordinate)) return -1;
        points[index] = @floatFromInt(coordinate);
    }

    var centers = [2]f32{ points[0], points[1] };
    var old_counts = [_]usize{0} ** 2;
    for (0..MAX_MOVES) |_| {
        var sums = [_]f32{0.0} ** 2;
        var counts = [_]usize{0} ** 2;
        for (0..point_count) |index| {
            const point = points[index];
            const first_delta = point - centers[0];
            const second_delta = centers[1] - point;
            const first_distance = first_delta * first_delta;
            const second_distance = second_delta * second_delta;
            const cluster: usize = if (second_distance < first_distance) 1 else 0;
            sums[cluster] = sums[cluster] + point;
            counts[cluster] += 1;
        }
        if (counts[0] == 0 or counts[1] == 0) return -1;
        const moved = [2]f32{
            sums[0] / @as(f32, @floatFromInt(counts[0])),
            sums[1] / @as(f32, @floatFromInt(counts[1])),
        };
        if (moved[0] == centers[0] and moved[1] == centers[1] and
            counts[0] == old_counts[0] and counts[1] == old_counts[1]) {
            const code0 = @as(i64, @intFromFloat(moved[0] * 256.0)) + CENTER_BIAS;
            const code1 = @as(i64, @intFromFloat(moved[1] * 256.0)) + CENTER_BIAS;
            if (code0 < 1 or code0 > 8193 or code1 < 1 or code1 > 8193) return -1;
            return (code0 * CENTER_BASE + code1) * 81 +
                @as(i64, @intCast(counts[0])) * 9 + @as(i64, @intCast(counts[1]));
        }
        centers = moved;
        old_counts = counts;
    }
    return -2;
}
