const MAX_COMPONENT: i64 = 1_000_000_000;

const Bounds = struct {
	lower_num: i64,
	lower_den: i64,
	upper_num: i64,
	upper_den: i64,
};

fn gcdPositive(left_input: i64, right_input: i64) i64 {
	var left = left_input;
	var right = right_input;
	while (right != 0) {
		const remainder = @rem(left, right);
		left = right;
		right = remainder;
	}
	return left;
}

fn boundedNeighbors(limit: i64, x: i64, y: i64) Bounds {
	const divisor = gcdPositive(x, y);
	const reduced_x = @divTrunc(x, divisor);
	const reduced_y = @divTrunc(y, divisor);
	if (reduced_x <= limit and reduced_y <= limit) {
		return .{ .lower_num = reduced_x, .lower_den = reduced_y,
			.upper_num = reduced_x, .upper_den = reduced_y };
	}

	var a: i64 = 0;
	var b: i64 = 1;
	var c: i64 = 1;
	var d: i64 = 0;
	while (true) {
		const middle_num = a + c;
		const middle_den = b + d;
		if (middle_num > limit or middle_den > limit) break;
		const target_side = middle_num * y;
		const middle_side = middle_den * x;
		if (target_side == middle_side) {
			return .{ .lower_num = middle_num, .lower_den = middle_den,
				.upper_num = middle_num, .upper_den = middle_den };
		}
		if (target_side < middle_side) {
			const lower_gap = b * x - a * y;
			const upper_gap = c * y - d * x;
			var step = @divTrunc(lower_gap, upper_gap);
			step = @min(step, @divTrunc(limit - a, c));
			if (d > 0) step = @min(step, @divTrunc(limit - b, d));
			a += step * c;
			b += step * d;
		} else {
			const upper_gap = c * y - d * x;
			const lower_gap = b * x - a * y;
			var step = @divTrunc(upper_gap, lower_gap);
			if (a > 0) step = @min(step, @divTrunc(limit - c, a));
			step = @min(step, @divTrunc(limit - d, b));
			c += step * a;
			d += step * b;
		}
	}
	return .{ .lower_num = a, .lower_den = b, .upper_num = c, .upper_den = d };
}

fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
	const bits: u64 = @bitCast(value);
	for (0..8) |byte| output[offset + byte] = @intCast((bits >> @intCast(byte * 8)) & 0xff);
}

/// Packed input [N, x, y]; writes four little-endian fraction components.
export fn rational_approximation(values: [*c]const i64, length: usize,
	output: [*c]u8, capacity: usize) i64 {
	if (values == null or length != 3) return -1;
	const limit = values[0];
	const x = values[1];
	const y = values[2];
	if (limit < 1 or limit > MAX_COMPONENT or x < 1 or x > MAX_COMPONENT or
		y < 1 or y > MAX_COMPONENT) return -1;
	if (output == null or capacity < 32) return -2;
	const bounds = boundedNeighbors(limit, x, y);
	storeI64Le(output, 0, bounds.lower_num);
	storeI64Le(output, 8, bounds.lower_den);
	storeI64Le(output, 16, bounds.upper_num);
	storeI64Le(output, 24, bounds.upper_den);
	return 32;
}
