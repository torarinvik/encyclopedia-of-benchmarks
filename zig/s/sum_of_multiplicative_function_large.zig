const std = @import("std");

const MODULUS: i64 = 469_762_049;
const MAX_N: i64 = 100_000_000;

fn floorSqrt(value: i64) i64 {
	var low: i64 = 1;
	var high: i64 = 10_000;
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

fn triangularMod(value: i64) i64 {
	var left = value;
	var right = value + 1;
	if (@rem(left, 2) == 0) left = @divTrunc(left, 2) else right = @divTrunc(right, 2);
	return @rem(left, MODULUS) * @rem(right, MODULUS) % MODULUS;
}

fn valueIndex(value: i64, n: i64, root: i64, size: usize) usize {
	if (value <= root) return size - @as(usize, @intCast(value));
	return @intCast(@divTrunc(n, value));
}

export fn sum_of_multiplicative_function_large(input: [*c]const i64, length: usize) i64 {
	if (input == null or length != 3) return -1;
	const n = input[0];
	const a = input[1];
	const b = input[2];
	if (n < 1 or n > MAX_N or a < 0 or a >= MODULUS or b < 0 or b >= MODULUS) return -1;

	const root = floorSqrt(n);
	var high_count: usize = @intCast(@divTrunc(n, root));
	while (high_count > 1 and @divTrunc(n, @as(i64, @intCast(high_count - 1))) == root) high_count -= 1;
	const size = high_count + @as(usize, @intCast(root));
	const allocator = std.heap.page_allocator;
	const quotients = allocator.alloc(i64, size) catch return -1;
	defer allocator.free(quotients);
	const prime_count = allocator.alloc(i64, size) catch return -1;
	defer allocator.free(prime_count);
	const prime_sum = allocator.alloc(i64, size) catch return -1;
	defer allocator.free(prime_sum);
	const composite = allocator.alloc(u8, @as(usize, @intCast(root)) + 1) catch return -1;
	defer allocator.free(composite);
	const primes = allocator.alloc(i64, @as(usize, @intCast(root)) + 1) catch return -1;
	defer allocator.free(primes);
	const values = allocator.alloc(i64, size) catch return -1;
	defer allocator.free(values);
	const next_values = allocator.alloc(i64, size) catch return -1;
	defer allocator.free(next_values);
	@memset(quotients, 0);
	@memset(prime_count, 0);
	@memset(prime_sum, 0);
	@memset(composite, 0);
	@memset(values, 0);
	@memset(next_values, 0);

	var index: usize = 1;
	while (index < high_count) : (index += 1) quotients[index] = @divTrunc(n, @as(i64, @intCast(index)));
	var value: i64 = 1;
	while (value <= root) : (value += 1) quotients[size - @as(usize, @intCast(value))] = value;

	var prime_total: usize = 0;
	value = 2;
	while (value <= root) : (value += 1) {
		if (composite[@intCast(value)] != 0) continue;
		primes[prime_total] = value;
		prime_total += 1;
		if (value <= @divTrunc(root, value)) {
			var multiple = value * value;
			while (multiple <= root) : (multiple += value) composite[@intCast(multiple)] = 1;
		}
	}

	index = 1;
	while (index < size) : (index += 1) {
		prime_count[index] = quotients[index] - 1;
		prime_sum[index] = normalize(triangularMod(quotients[index]) - 1);
	}
	var preceding_count: i64 = 0;
	var preceding_sum: i64 = 0;
	var p_index: usize = 0;
	while (p_index < prime_total) : (p_index += 1) {
		const prime = primes[p_index];
		const square = prime * prime;
		index = 1;
		while (index < size and quotients[index] >= square) : (index += 1) {
			const quotient_index = valueIndex(@divTrunc(quotients[index], prime), n, root, size);
			prime_count[index] -= prime_count[quotient_index] - preceding_count;
			const sum_delta = normalize(prime_sum[quotient_index] - preceding_sum);
			prime_sum[index] = normalize(prime_sum[index] - @rem(prime, MODULUS) * sum_delta);
		}
		preceding_count += 1;
		preceding_sum = normalize(preceding_sum + prime);
	}
	index = 1;
	while (index < size) : (index += 1) {
		values[index] = (a * @rem(prime_count[index], MODULUS) + b * prime_sum[index]) % MODULUS;
		next_values[index] = values[index];
	}

	p_index = prime_total;
	while (p_index > 0) {
		p_index -= 1;
		const prime = primes[p_index];
		var power = prime;
		var exponent: i64 = 1;
		const prime_prefix = values[valueIndex(prime, n, root, size)];
		while (@divTrunc(n, prime) >= power) {
			const local = @rem(a * exponent + b * prime, MODULUS);
			const next_local = @rem(a * (exponent + 1) + b * prime, MODULUS);
			const next_power = power * prime;
			index = 1;
			while (index < size and next_power <= quotients[index]) : (index += 1) {
				const quotient_index = valueIndex(@divTrunc(quotients[index], power), n, root, size);
				const non_prime_sum = normalize(values[quotient_index] - prime_prefix);
				next_values[index] = normalize(next_values[index] + local * non_prime_sum + next_local);
			}
			power = next_power;
			exponent += 1;
		}
		var copied = valueIndex(prime * prime, n, root, size) + 1;
		if (copied > size) copied = size;
		index = 0;
		while (index < copied) : (index += 1) values[index] = next_values[index];
	}
	return normalize(values[valueIndex(n, n, root, size)] + 1);
}
