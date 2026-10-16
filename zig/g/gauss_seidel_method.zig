fn put_f64_le(output: [*]u8, offset: usize, value: f64) void {
	const bits: u64 = @bitCast(value);
	for (0..8) |b| output[offset+b] = @truncate(bits >> @intCast(8*b));
}

export fn gauss_seidel_method(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
	if (input == null or length < 1 or input[0] < 1 or input[0] > 8) return -1;
	const n: usize = @intCast(input[0]);
	if (length != 1+n*n+n) return -1;
	const rhs = 1+n*n;
	for (1..length) |k| if (input[k] < -1_000_000_000 or input[k] > 1_000_000_000) return -1;
	for (0..n) |row| {
		const diagonal = input[1+row*n+row];
		if (diagonal <= 0) return -1;
		var off_sum: i64 = 0;
		for (0..n) |col| {
			const value = input[1+row*n+col];
			if (value != input[1+col*n+row]) return -1;
			if (row != col) off_sum += if (value < 0) -value else value;
		}
		if (diagonal <= off_sum) return -1;
	}
	if (output == null or capacity < n*8) return -2;
	var a: [64]f64 = @splat(0);
	var b: [8]f64 = @splat(0);
	var x: [8]f64 = @splat(0);
	var old: [8]f64 = @splat(0);
	for (0..n*n) |i| a[i] = @as(f64, @floatFromInt(input[i+1]))/1_000_000.0;
	for (0..n) |i| b[i] = @as(f64, @floatFromInt(input[rhs+i]))/1_000_000.0;
	for (0..1000) |_| {
		for (0..n) |i| old[i] = x[i];
		for (0..n) |i| {
			var before: f64 = 0;
			var after: f64 = 0;
			for (0..i) |j| before += a[i*n+j]*x[j];
			for (i+1..n) |j| after += a[i*n+j]*old[j];
			x[i] = (b[i]-before-after)/a[i*n+i];
		}
		var done = true;
		for (0..n) |i| if (@abs(x[i]-old[i]) >= 1.0e-10) { done = false; };
		if (done) break;
	}
	for (0..n) |i| put_f64_le(output, i*8, @round(x[i]*1.0e10)/1.0e10);
	return @intCast(n*8);
}
