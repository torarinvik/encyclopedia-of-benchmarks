const MAX_DIMENSION: usize = 64;
const INVALID_RESULT: f64 = -1e300;

export fn gesummv(values: ?[*]const i64, length: usize) f64 {
    const input = values orelse return INVALID_RESULT;
    if (length != 1 or input[0] < 1 or input[0] > MAX_DIMENSION) return INVALID_RESULT;
    const n: usize = @intCast(input[0]);
    var x = [_]f64{0} ** MAX_DIMENSION;
    for (0..n) |i| x[i] = @as(f64, @floatFromInt(i % n)) / @as(f64, @floatFromInt(n));
    var result: f64 = 0;
    for (0..n) |i| {
        var temporary: f64 = 0;
        var y: f64 = 0;
        for (0..n) |j| {
            const a = @as(f64, @floatFromInt((i * j + 1) % n)) / @as(f64, @floatFromInt(n));
            const b = @as(f64, @floatFromInt((i * j + 2) % n)) / @as(f64, @floatFromInt(n));
            temporary = a * x[j] + temporary;
            y = b * x[j] + y;
        }
        y = 1.5 * temporary + 1.2 * y;
        result += y;
    }
    return result;
}
