const MAX_POINTS: usize = 29;
const Point32 = struct { x: f32, y: f32 };

export fn koch_snowflake(input: ?[*]const f64, length: usize,
    output: ?[*]f64, output_capacity: usize) i64 {
    if (input == null or length < 2 or length > 20) return -1;
    const values = input.?;
    const steps_value = values[0];
    const count_value = values[1];
    if (steps_value != 0.0 and steps_value != 1.0) return -1;
    if (count_value != 2.0 and count_value != 3.0 and count_value != 4.0 and count_value != 5.0 and
        count_value != 6.0 and count_value != 7.0 and count_value != 8.0) return -1;
    const steps: usize = @intFromFloat(steps_value);
    const point_count: usize = @intFromFloat(count_value);
    if (length != 2 + 2 * point_count) return -1;
    for (0..2 * point_count) |i| {
        const value = values[i + 2];
        if (value != value or value < -1000.0 or value > 1000.0) return -1;
    }
    const result_points = if (steps == 0) point_count else 4 * (point_count - 1) + 1;
    const result_count = 2 * result_points;
    if (output == null or output_capacity < result_count) return -2;

    var first: [MAX_POINTS]Point32 = undefined;
    var second: [MAX_POINTS]Point32 = undefined;
    for (0..point_count) |i| {
        first[i] = .{ .x = @floatCast(values[2 + 2*i]), .y = @floatCast(values[3 + 2*i]) };
    }
    var source = &first;
    var destination = &second;
    var source_count = point_count;
    for (0..steps) |_| {
        var cursor: usize = 0;
        for (0..source_count - 1) |i| {
            const start = source[i];
            const finish = source[i + 1];
            const dx = finish.x - start.x;
            const dy = finish.y - start.y;
            const tx = dx / 3.0;
            const ty = dy / 3.0;
            const x1 = start.x + tx;
            const y1 = start.y + ty;
            const rx = 0.49999997 * tx - 0.86602545 * ty;
            const ry = 0.86602545 * tx + 0.49999997 * ty;
            const tx2 = (dx * 2.0) / 3.0;
            const ty2 = (dy * 2.0) / 3.0;
            destination[cursor] = start; cursor += 1;
            destination[cursor] = .{ .x = x1, .y = y1 }; cursor += 1;
            destination[cursor] = .{ .x = x1 + rx, .y = y1 + ry }; cursor += 1;
            destination[cursor] = .{ .x = start.x + tx2, .y = start.y + ty2 }; cursor += 1;
        }
        destination[cursor] = source[source_count - 1]; cursor += 1;
        source_count = cursor;
        const temp = source; source = destination; destination = temp;
    }
    const dest = output.?;
    for (0..result_points) |i| {
        dest[2*i] = @floatCast(source[i].x);
        dest[2*i + 1] = @floatCast(source[i].y);
    }
    return @intCast(result_count);
}
