const std = @import("std");
const MAX_NODES: usize = 4;

export fn page_rank(input: ?[*]const f64, input_length: usize,
    output: ?[*]f64, capacity: usize) i64 {
    const values = input orelse return -1;
    if (input_length < 6 or input_length > 18) return -1;
    if (!std.math.isFinite(values[0]) or !std.math.isFinite(values[1]) or
        @trunc(values[0]) != values[0] or @trunc(values[1]) != values[1] or
        values[0] < 2 or values[0] > 4 or values[1] < 0 or values[1] > 8) return -1;
    const nodes: usize = @intFromFloat(values[0]);
    const iterations: usize = @intFromFloat(values[1]);
    if (input_length != 2 + nodes * nodes) return -1;
    var matrix = [_]u8{0} ** 16;
    var degrees = [_]usize{0} ** MAX_NODES;
    for (0..nodes) |row| {
        for (0..nodes) |column| {
            const value = values[2 + row * nodes + column];
            if (!std.math.isFinite(value) or (value != 0 and value != 1) or (row == column and value != 0)) return -1;
            matrix[row * nodes + column] = @intFromFloat(value);
            degrees[row] += matrix[row * nodes + column];
        }
    }
    var ranks = [_]f64{0} ** MAX_NODES;
    for (0..nodes) |i| ranks[i] = 1.0 / @as(f64, @floatFromInt(nodes));
    for (0..iterations) |_| {
        var dangling_sum: f64 = 0;
        for (0..nodes) |source| if (degrees[source] == 0) { dangling_sum += ranks[source]; };
        const dangling_share = (dangling_sum * 0.5) / @as(f64, @floatFromInt(nodes));
        const baseline = 0.5 / @as(f64, @floatFromInt(nodes)) + dangling_share;
        var next = [_]f64{0} ** MAX_NODES;
        for (0..nodes) |target| {
            var incoming: f64 = 0;
            for (0..nodes) |source| {
                if (matrix[source * nodes + target] == 1) incoming += ranks[source] / @as(f64, @floatFromInt(degrees[source]));
            }
            next[target] = baseline + incoming * 0.5;
        }
        ranks = next;
    }
    const out = output orelse return -2;
    if (capacity < nodes) return -2;
    @memcpy(out[0..nodes], ranks[0..nodes]);
    return @intCast(nodes);
}
