const std = @import("std");

const TABLE_SIZE: usize = 65_536;
const TABLE_MASK: usize = TABLE_SIZE - 1;
const MAX_MODULUS: u64 = 1_000_000_000;

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
	var high: u64 = 31_623;
	while (low < high) {
		const middle = low + (high - low) / 2;
		if (middle * middle >= value) high = middle else low = middle + 1;
	}
	return low;
}

fn powMod(base_value: u64, exponent_value: u64, modulus: u64) u64 {
	var base = base_value;
	var exponent = exponent_value;
	var result: u64 = 1 % modulus;
	while (exponent != 0) {
		if ((exponent & 1) != 0) result = (result * base) % modulus;
		base = (base * base) % modulus;
		exponent >>= 1;
	}
	return result;
}

fn inverseMod(value: u64, modulus: u64) ?u64 {
	var old_r: i64 = @intCast(value);
	var r: i64 = @intCast(modulus);
	var old_t: i64 = 1;
	var t: i64 = 0;
	while (r != 0) {
		const quotient = @divTrunc(old_r, r);
		const next_r = old_r - quotient * r;
		const next_t = old_t - quotient * t;
		old_r = r;
		r = next_r;
		old_t = t;
		t = next_t;
	}
	if (old_r != 1) return null;
	const mod_i: i64 = @intCast(modulus);
	var normalized = @rem(old_t, mod_i);
	if (normalized < 0) normalized += mod_i;
	return @intCast(normalized);
}

fn insertBaby(keys: []u64, steps: []u32, key: u64, step: u32) void {
	var slot: usize = @intCast(key & TABLE_MASK);
	while (steps[slot] != 0) {
		if (keys[slot] == key) return;
		slot = (slot + 1) & TABLE_MASK;
	}
	keys[slot] = key;
	steps[slot] = step + 1;
}

fn findBaby(keys: []const u64, steps: []const u32, key: u64) ?u64 {
	var slot: usize = @intCast(key & TABLE_MASK);
	while (steps[slot] != 0) {
		if (keys[slot] == key) return steps[slot] - 1;
		slot = (slot + 1) & TABLE_MASK;
	}
	return null;
}

fn coprimeLog(x: u64, y: u64, modulus: u64) i64 {
	if (y == 1 % modulus) return 0;
	const width = ceilSqrt(modulus);
	const allocator = std.heap.page_allocator;
	const keys = allocator.alloc(u64, TABLE_SIZE) catch return -1;
	defer allocator.free(keys);
	const steps = allocator.alloc(u32, TABLE_SIZE) catch return -1;
	defer allocator.free(steps);
	@memset(steps, 0);
	var residue: u64 = 1 % modulus;
	var step: u64 = 0;
	while (step < width) : (step += 1) {
		insertBaby(keys, steps, residue, @intCast(step));
		residue = (residue * x) % modulus;
	}
	const inverse = inverseMod(x, modulus) orelse return -1;
	const giant_factor = powMod(inverse, width, modulus);
	var giant = y;
	var block: u64 = 0;
	while (block * width <= modulus) : (block += 1) {
		if (findBaby(keys, steps, giant)) |baby| {
			const answer = block * width + baby;
			if (answer <= modulus) return @intCast(answer);
			return -1;
		}
		giant = (giant * giant_factor) % modulus;
	}
	return -1;
}

fn extendedLog(x: u64, initial_y: u64, initial_modulus: u64) i64 {
	var y = initial_y;
	var modulus = initial_modulus;
	if (modulus == 1) return 0;
	var accumulator: u64 = 1;
	var added: u64 = 0;
	while (gcdU64(x, modulus) > 1) {
		const divisor = gcdU64(x, modulus);
		if (y == accumulator) return @intCast(added);
		if (y % divisor != 0) return -1;
		y /= divisor;
		modulus /= divisor;
		accumulator = (accumulator * (x / divisor)) % modulus;
		added += 1;
		if (modulus == 1) return @intCast(added);
	}
	const inverse = inverseMod(accumulator, modulus) orelse return -1;
	const reduced_target = (y * inverse) % modulus;
	const remaining = coprimeLog(x % modulus, reduced_target, modulus);
	if (remaining < 0) return -1;
	return @as(i64, @intCast(added)) + remaining;
}

/// Packed input [x, y, m]; return the least nonnegative exponent or -1.
export fn discrete_logarithm_mod(values: [*c]const i64, length: usize) i64 {
	if (values == null or length != 3) return -1;
	const x_input = values[0];
	const y_input = values[1];
	const modulus_input = values[2];
	if (x_input < 0 or y_input < 0 or modulus_input < 1 or
		@as(u64, @intCast(modulus_input)) > MAX_MODULUS or
		x_input >= modulus_input or y_input >= modulus_input) return -1;
	return extendedLog(@intCast(x_input), @intCast(y_input), @intCast(modulus_input));
}
