fn javaRound(value: f64) i64 { return @intFromFloat(@floor(value + 0.5)); }
fn writeI64(output: [*c]u8, position: *usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |i| { output[position.*] = @truncate(bits >> @intCast(i * 8)); position.* += 1; }
}
pub export fn ddaline(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input == null or length != 4) return -1;
    for (0..4) |i| if (input[i] < -128 or input[i] > 128) return -1;
    const dx = input[2] - input[0];
    const dy = input[3] - input[1];
    const ax = if (dx < 0) -dx else dx;
    const ay = if (dy < 0) -dy else dy;
    const steps = @max(ax, ay);
    if (steps > 256) return -1;
    const output_bytes: usize = (@as(usize, @intCast(steps)) + 1) * 16;
    if (output == null or capacity < output_bytes) return -2;
    var position: usize = 0;
    if (steps == 0) { writeI64(output, &position, input[0]); writeI64(output, &position, input[1]); return 16; }
    const x_inc = @as(f64, @floatFromInt(dx)) / @as(f64, @floatFromInt(steps));
    const y_inc = @as(f64, @floatFromInt(dy)) / @as(f64, @floatFromInt(steps));
    var x = @as(f64, @floatFromInt(input[0]));
    var y = @as(f64, @floatFromInt(input[1]));
    for (0..@as(usize, @intCast(steps)) + 1) |_| {
        writeI64(output, &position, javaRound(x));
        writeI64(output, &position, javaRound(y));
        x += x_inc;
        y += y_inc;
    }
    return @intCast(output_bytes);
}
