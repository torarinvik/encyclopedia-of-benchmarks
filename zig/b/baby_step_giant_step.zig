const std = @import("std");

const TABLE_SIZE: usize = 65_536;
const TABLE_MASK: usize = TABLE_SIZE - 1;
const MAX_MODULUS: u64 = 1_000_000_007;

fn gcdU64(left: u64, right: u64) u64 {
	var a = left;
	var b = right;
	while (b != 0) {
		const remainder = a % b;
		a = b;
		b = remainder;
	}
	return a;
}

fn ceilSqrt(value: u64) u64 {
	var low: u64 = 1;
	var high: u64 = 31_624;
	while (low < high) {
		const middle = low + (high - low) / 2;
		if (middle * middle >= value) high = middle else low = middle + 1;
	}
	return low;
}

fn insertBaby(keys: []u64, encoded_steps: []u32, key: u64, step: u32) void {
	var slot: usize = @intCast(key & TABLE_MASK);
	while (encoded_steps[slot] != 0 and keys[slot] != key) slot = (slot + 1) & TABLE_MASK;
	keys[slot] = key;
	encoded_steps[slot] = step + 1;
}

fn findBaby(keys: []const u64, encoded_steps: []const u32, key: u64) ?u64 {
	var slot: usize = @intCast(key & TABLE_MASK);
	while (encoded_steps[slot] != 0) {
		if (keys[slot] == key) return encoded_steps[slot] - 1;
		slot = (slot + 1) & TABLE_MASK;
	}
	return null;
}

/// Packed input [a, b, n]; return the least positive discrete logarithm or -1.
export fn baby_step_giant_step(values: [*c]const i64, length: usize) i64 {
	if (values == null or length != 3) return -1;
	const a_input = values[0];
	const b_input = values[1];
	const modulus_input = values[2];
	if (a_input < 0 or b_input < 0 or modulus_input < 1 or
		@as(u64, @intCast(modulus_input)) > MAX_MODULUS or
		a_input >= modulus_input or b_input >= modulus_input) return -1;
	const a: u64 = @intCast(a_input);
	const b: u64 = @intCast(b_input);
	const modulus: u64 = @intCast(modulus_input);
	if (gcdU64(a, modulus) != 1) return -1;

	const m = ceilSqrt(modulus);
	const keys = std.heap.page_allocator.alloc(u64, TABLE_SIZE) catch return -1;
	defer std.heap.page_allocator.free(keys);
	const encoded_steps = std.heap.page_allocator.alloc(u32, TABLE_SIZE) catch return -1;
	defer std.heap.page_allocator.free(encoded_steps);
	@memset(encoded_steps, 0);
	var step: u64 = 1;
	var index: u64 = 0;
	while (index < m) : (index += 1) {
		insertBaby(keys, encoded_steps, (step * b) % modulus, @intCast(index));
		step = (step * a) % modulus;
	}
	const giant_step = step;
	index = m;
	while (index <= modulus) : (index += m) {
		if (findBaby(keys, encoded_steps, step)) |baby_index| return @intCast(index - baby_index);
		step = (step * giant_step) % modulus;
	}
	return -1;
}
