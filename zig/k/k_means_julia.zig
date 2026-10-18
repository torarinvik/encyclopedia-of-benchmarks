const MAX_MOVES: usize = 64;
const CENTER_SCALE: f64 = 256.0;
const CENTER_BIAS: i64 = 4097;
const CENTER_BASE: i64 = 8194;

export fn k_means_julia(input: ?[*]const i64, length: usize) i64 {
    const values = input orelse return -1;
    if (length < 2 or length > 10) return -1;
    if (values[0] < 3 or values[0] > 8) return -1;
    const n: usize = @intCast(values[0]);
    if (length != n + 1) return -1;

    var points = [_]f64{0.0} ** 8;
    for (0..n) |index| {
        const coordinate = values[index + 1];
        if (coordinate < -16 or coordinate > 16 or (index > 0 and values[index] >= coordinate)) return -1;
        points[index] = @floatFromInt(coordinate);
    }

    var centers = [2]f64{ points[0], points[n / 2] };
    for (0..MAX_MOVES) |_| {
        var sums = [_]f64{0.0} ** 2;
        var counts = [_]usize{0} ** 2;
        for (0..n) |index| {
            const d0 = points[index] - centers[0];
            const d1 = points[index] - centers[1];
            const cluster: usize = if (d1 * d1 < d0 * d0) 1 else 0;
            sums[cluster] += points[index];
            counts[cluster] += 1;
        }
        if (counts[0] == 0 or counts[1] == 0) return -1;
        const moved = [2]f64{
            sums[0] / @as(f64, @floatFromInt(counts[0])),
            sums[1] / @as(f64, @floatFromInt(counts[1])),
        };
        if (moved[0] == centers[0] and moved[1] == centers[1]) {
            const code0 = @as(i64, @intFromFloat(moved[0] * CENTER_SCALE)) + CENTER_BIAS;
            const code1 = @as(i64, @intFromFloat(moved[1] * CENTER_SCALE)) + CENTER_BIAS;
            if (code0 < 1 or code0 > 8193 or code1 < 1 or code1 > 8193) return -1;
            return code0 * CENTER_BASE + code1;
        }
        centers = moved;
    }
    return -2;
}
