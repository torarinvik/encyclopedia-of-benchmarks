const std = @import("std");

fn writeU32Le(value: u32, output: [*]u8, position: usize) void {
	for (0..4) |byte| output[position + byte] = @truncate(value >> @intCast(8 * byte));
}

/// Sieve through n, then emit ascending prime/exponent pairs as little-endian u32 values.
export fn prime_factorization_sieve(value: i64, output: [*c]u8,
	output_capacity: usize) i64 {
	if (value < 1 or value > 1_000_005) return -1;
	if (value == 1) return 0;
	const limit: usize = @intCast(value);
	const is_prime = std.heap.page_allocator.alloc(bool, limit + 1) catch return -2;
	defer std.heap.page_allocator.free(is_prime);
	@memset(is_prime, true);
	is_prime[0] = false;
	is_prime[1] = false;
	var prime: usize = 2;
	while (prime <= limit / prime) : (prime += 1) {
		if (!is_prime[prime]) continue;
		var multiple = prime * prime;
		while (multiple <= limit) : (multiple += prime) is_prime[multiple] = false;
	}

	var primes: [10]u32 = undefined;
	var exponents: [10]u32 = undefined;
	var count: usize = 0;
	var remaining = value;
	for (2..limit + 1) |candidate| {
		if (remaining == 1) break;
		if (!is_prime[candidate]) continue;
		var exponent: u32 = 0;
		while (@rem(remaining, @as(i64, @intCast(candidate))) == 0) {
			remaining = @divTrunc(remaining, @as(i64, @intCast(candidate)));
			exponent += 1;
		}
		if (exponent != 0) {
			primes[count] = @intCast(candidate);
			exponents[count] = exponent;
			count += 1;
		}
	}
	const required = count * 8;
	if (output == null or output_capacity < required) return -2;
	for (0..count) |index| {
		writeU32Le(primes[index], output, 8 * index);
		writeU32Le(exponents[index], output, 8 * index + 4);
	}
	return @intCast(required);
}
