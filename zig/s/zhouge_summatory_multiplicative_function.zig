const std = @import("std");

const MODULUS: i64 = 469_762_049;
const MAX_N: i64 = 10_000_000;

fn floorSqrt(value: i64) i64 {
	var low: i64 = 1;
	var high: i64 = 3162;
	while (low < high) {
		const middle = low + @divTrunc(high - low + 1, 2);
		if (middle <= @divTrunc(value, middle)) low = middle else high = middle - 1;
	}
	return low;
}

fn normalize(value: i64) i64 {
	const remainder = @rem(value, MODULUS);
	return if (remainder < 0) remainder + MODULUS else remainder;
}

fn quotientAt(index: usize, n: i64, high_count: usize, size: usize) i64 {
	if (index < high_count) return @divTrunc(n, @as(i64, @intCast(index)));
	return @intCast(size - index);
}

fn valueIndex(value: i64, n: i64, root: i64, size: usize) usize {
	if (value <= root) return size - @as(usize, @intCast(value));
	return @intCast(@divTrunc(n, value));
}

fn upperBound(primes: []const i64, value: i64) usize {
	var low: usize = 0;
	var high = primes.len;
	while (low < high) {
		const middle = low + (high - low) / 2;
		if (primes[middle] <= value) low = middle + 1 else high = middle;
	}
	return low;
}

fn applySkippedPrimeRange(index: usize, stage: usize, small_lo: []const u32,
	small_hi: []const u32, simple_cursor: []u32, prefix_g: []const i64,
	smooth_sum: []i64) void {
	var next: u32 = @intCast(stage + 1);
	if (next < small_lo[index]) next = small_lo[index];
	if (next > small_hi[index]) next = small_hi[index];
	const old = simple_cursor[index];
	if (next < old) {
		smooth_sum[index] = normalize(smooth_sum[index] + prefix_g[@intCast(old)] - prefix_g[@intCast(next)]);
		simple_cursor[index] = next;
	}
}

fn applySkippedPowerSums(index: usize, stage: usize, small_lo: []const u32,
	small_hi: []const u32, g_cursor: []u32, prefix_sum: []const i64,
	g_zero: []i64, g_one: []i64) void {
	var next: u32 = @intCast(stage);
	if (next < small_lo[index]) next = small_lo[index];
	if (next > small_hi[index]) next = small_hi[index];
	const old = g_cursor[index];
	if (next > old) {
		g_zero[index] = normalize(g_zero[index] - @as(i64, @intCast(next - old)));
		g_one[index] = normalize(g_one[index] - (prefix_sum[@intCast(next)] - prefix_sum[@intCast(old)]));
		g_cursor[index] = next;
	}
}

fn smallValue(value_input: i64, smallest: []const u32, a: i64, b: i64) i64 {
	var value = value_input;
	var result: i64 = 1;
	while (value > 1) {
		const prime: i64 = @intCast(smallest[@intCast(value)]);
		var exponent: i64 = 0;
		while (@rem(value, prime) == 0) {
			value = @divTrunc(value, prime);
			exponent += 1;
		}
		result = @rem(result * @rem(a * exponent + b * prime, MODULUS), MODULUS);
	}
	return result;
}

export fn zhouge_summatory_multiplicative_function(input: [*c]const i64, length: usize) i64 {
	if (input == null or length != 3) return -1;
	const n = input[0];
	const a = input[1];
	const b = input[2];
	if (n < 1 or n > MAX_N or a < 0 or a >= MODULUS or b < 0 or b >= MODULUS) return -1;

	const root = floorSqrt(n);
	var high_count: usize = @intCast(@divTrunc(n, root));
	while (high_count > 1 and @divTrunc(n, @as(i64, @intCast(high_count - 1))) == root) high_count -= 1;
	const size = high_count + @as(usize, @intCast(root));
	const root_size = @as(usize, @intCast(root)) + 1;
	const allocator = std.heap.page_allocator;
	const smallest = allocator.alloc(u32, root_size) catch return -1;
	defer allocator.free(smallest);
	const primes = allocator.alloc(i64, root_size) catch return -1;
	defer allocator.free(primes);
	const g_zero = allocator.alloc(i64, size) catch return -1;
	defer allocator.free(g_zero);
	const g_one = allocator.alloc(i64, size) catch return -1;
	defer allocator.free(g_one);
	const smooth_sum = allocator.alloc(i64, size) catch return -1;
	defer allocator.free(smooth_sum);
	const small_lo = allocator.alloc(u32, size) catch return -1;
	defer allocator.free(small_lo);
	const small_hi = allocator.alloc(u32, size) catch return -1;
	defer allocator.free(small_hi);
	const simple_cursor = allocator.alloc(u32, size) catch return -1;
	defer allocator.free(simple_cursor);
	const g_cursor = allocator.alloc(u32, size) catch return -1;
	defer allocator.free(g_cursor);
	@memset(smallest, 0);
	@memset(g_zero, 0);
	@memset(g_one, 0);
	@memset(smooth_sum, 1);
	@memset(small_lo, 0);
	@memset(small_hi, 0);
	@memset(simple_cursor, 0);
	@memset(g_cursor, 0);

	var prime_total: usize = 0;
	var value: i64 = 2;
	while (value <= root) : (value += 1) {
		if (smallest[@intCast(value)] != 0) continue;
		smallest[@intCast(value)] = @intCast(value);
		primes[prime_total] = value;
		prime_total += 1;
		if (value <= @divTrunc(root, value)) {
			var multiple = value * value;
			while (multiple <= root) : (multiple += value) {
				if (smallest[@intCast(multiple)] == 0) smallest[@intCast(multiple)] = @intCast(value);
			}
		}
	}
	const prime_values = primes[0..prime_total];
	const prefix_sum = allocator.alloc(i64, prime_total + 1) catch return -1;
	defer allocator.free(prefix_sum);
	const prefix_g = allocator.alloc(i64, prime_total + 1) catch return -1;
	defer allocator.free(prefix_g);
	prefix_sum[0] = 0;
	prefix_g[0] = 0;
	for (prime_values, 0..) |prime, index| {
		prefix_sum[index + 1] = normalize(prefix_sum[index] + prime);
		prefix_g[index + 1] = normalize(prefix_g[index] + a + b * prime);
	}

	for (1..size) |index| {
		const y = quotientAt(index, n, high_count, size);
		small_lo[index] = @intCast(upperBound(prime_values, floorSqrt(y)));
		small_hi[index] = @intCast(upperBound(prime_values, y));
		simple_cursor[index] = small_hi[index];
		g_cursor[index] = small_lo[index];
		g_zero[index] = @rem(y, MODULUS);
		var left = y;
		var right = y + 1;
		if (@rem(left, 2) == 0) left = @divTrunc(left, 2) else right = @divTrunc(right, 2);
		g_one[index] = @rem(@rem(left, MODULUS) * @rem(right, MODULUS), MODULUS);
	}

	for (prime_values, 0..) |prime, stage| {
		const square = prime * prime;
		for (1..size) |index| {
			const y = quotientAt(index, n, high_count, size);
			if (y < square) break;
			const child = valueIndex(@divTrunc(y, prime), n, root, size);
			applySkippedPowerSums(child, stage, small_lo, small_hi, g_cursor, prefix_sum, g_zero, g_one);
			g_zero[index] = normalize(g_zero[index] - g_zero[child]);
			g_one[index] = normalize(g_one[index] - prime * g_one[child]);
		}
	}
	for (1..size) |index| applySkippedPowerSums(index, prime_total, small_lo, small_hi, g_cursor, prefix_sum, g_zero, g_one);

	var stage = prime_total;
	while (stage > 0) {
		stage -= 1;
		const prime = prime_values[stage];
		const square = prime * prime;
		for (1..size) |index| {
			const y = quotientAt(index, n, high_count, size);
			if (y < square) break;
			applySkippedPrimeRange(index, stage, small_lo, small_hi, simple_cursor, prefix_g, smooth_sum);
			var power = prime;
			var exponent: i64 = 1;
			while (power <= y) : (exponent += 1) {
				const child = valueIndex(@divTrunc(y, power), n, root, size);
				applySkippedPrimeRange(child, stage, small_lo, small_hi, simple_cursor, prefix_g, smooth_sum);
				const local = @rem(a * exponent + b * prime, MODULUS);
				smooth_sum[index] = normalize(smooth_sum[index] + local * smooth_sum[child]);
				power *= prime;
			}
		}
	}

	var answer = smooth_sum[1];
	var small: i64 = 1;
	while (small <= root) : (small += 1) {
		const child = valueIndex(@divTrunc(n, small), n, root, size);
		const large_prime_sum = normalize(a * normalize(g_zero[child] - 1) + b * normalize(g_one[child] - 1));
		answer = normalize(answer + smallValue(small, smallest, a, b) * large_prime_sum);
	}
	return answer;
}
