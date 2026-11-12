const modulus: i64 = 998244353;
const max_n: usize = 32;

fn modularPower(base_value: i64, exponent_value: i64) i64 {
	var base = base_value;
	var exponent = exponent_value;
	var result: i64 = 1;
	while (exponent > 0) {
		if (@rem(exponent, 2) != 0) result = @rem(result * base, modulus);
		base = @rem(base * base, modulus);
		exponent = @divTrunc(exponent, 2);
	}
	return result;
}

export fn bernoulli_number(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length != 1) return -1;
    const input = input_opt.?;
    const n64 = input[0];
    if (n64 < 0 or n64 > @as(i64, @intCast(max_n))) return -1;
    const n: usize = @intCast(n64);
    const output_bytes = 4 * (n + 1);
    if (output_opt == null or capacity < output_bytes) return -2;

    var inverse: [max_n + 2]i64 = @splat(0);
    var bernoulli: [max_n + 1]i64 = @splat(0);
    inverse[1] = 1;
    for (2..n + 2) |i| {
        inverse[i] = modularPower(@intCast(i), modulus - 2);
    }

    bernoulli[0] = 1;
    for (1..n + 1) |m| {
        var choose: i64 = 1;
        var total: i64 = 0;
        for (0..m) |k| {
            total = @rem(total + choose * bernoulli[k], modulus);
            choose = @rem(choose * @as(i64, @intCast(m + 1 - k)), modulus) * inverse[k + 1] % modulus;
        }
        bernoulli[m] = @rem(modulus - total, modulus) * inverse[m + 1] % modulus;
    }

    const output = output_opt.?;
    for (0..n + 1) |i| {
        const value: u32 = @intCast(bernoulli[i]);
        output[4 * i] = @truncate(value);
        output[4 * i + 1] = @truncate(value >> 8);
        output[4 * i + 2] = @truncate(value >> 16);
        output[4 * i + 3] = @truncate(value >> 24);
    }
    return @intCast(output_bytes);
}
