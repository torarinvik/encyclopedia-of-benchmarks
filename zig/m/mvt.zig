const MAX_DIMENSION: usize = 64;
const MAX_CELLS: usize = MAX_DIMENSION * MAX_DIMENSION;
const INVALID_RESULT: f64 = -1e300;

export fn mvt(values_opt: ?[*]const i64, length: usize) f64 {
    if (values_opt == null or length != 1) return INVALID_RESULT;
    const values = values_opt.?;
    if (values[0] < 1 or values[0] > @as(i64, @intCast(MAX_DIMENSION))) return INVALID_RESULT;
    const n: usize = @intCast(values[0]);
    var x1: [MAX_DIMENSION]f64 = [_]f64{0} ** MAX_DIMENSION;
    var x2: [MAX_DIMENSION]f64 = [_]f64{0} ** MAX_DIMENSION;
    var y1: [MAX_DIMENSION]f64 = [_]f64{0} ** MAX_DIMENSION;
    var y2: [MAX_DIMENSION]f64 = [_]f64{0} ** MAX_DIMENSION;
    var matrix: [MAX_CELLS]f64 = [_]f64{0} ** MAX_CELLS;
    for (0..n) |i| {
        x1[i] = @as(f64, @floatFromInt(i % n)) / @as(f64, @floatFromInt(n));
        x2[i] = @as(f64, @floatFromInt((i + 1) % n)) / @as(f64, @floatFromInt(n));
        y1[i] = @as(f64, @floatFromInt((i + 3) % n)) / @as(f64, @floatFromInt(n));
        y2[i] = @as(f64, @floatFromInt((i + 4) % n)) / @as(f64, @floatFromInt(n));
        for (0..n) |j| matrix[i * n + j] = @as(f64, @floatFromInt((i * j) % n)) / @as(f64, @floatFromInt(n));
    }
    for (0..n) |i| for (0..n) |j| { x1[i] = x1[i] + matrix[i * n + j] * y1[j]; };
    for (0..n) |i| for (0..n) |j| { x2[i] = x2[i] + matrix[j * n + i] * y2[j]; };
    var checksum: f64 = 0;
    for (0..n) |i| checksum += x1[i];
    for (0..n) |i| checksum += x2[i];
    return checksum;
}
