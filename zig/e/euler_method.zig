fn putF64Le(output: [*c]u8, offset: usize, value: f64) void {
	const bits: u64 = @bitCast(value)
	for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

pub export fn euler_method(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
	if (input == null or length != 4) return -1;
	if (input[0] < -8 or input[0] > 8 or input[1] < -8 or input[1] > 8 or input[2] < 1 or input[2] > 4 or input[3] < 1 or input[3] > 16) return -1;
	const steps: usize = @intCast(input[3]); const required = 8 * (steps + 1);
	if (output == null or capacity < required) return -2;
	const denominator: u64 = @as(u64, 1) << @intCast(input[2]);
	const h = 1.0 / @as(f64, @floatFromInt(denominator));
	var x: f64 = @floatFromInt(input[0]); var y: f64 = @floatFromInt(input[1]);
	putF64Le(output, 0, y);
	for (0..steps) |step| { y = y + h * (x + y); x += h; putF64Le(output, 8 * (step + 1), y); }
	return @intCast(required);
}
