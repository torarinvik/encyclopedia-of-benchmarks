fn put_f64_le(output: [*]u8, offset: usize, value: f64) void {
	const bits: u64 = @bitCast(value);
	for (0..8) |b| output[offset+b] = @truncate(bits >> @intCast(8*b));
}

fn round_even(value: f64) f64 {
	const low = @floor(value);
	const fraction = value - low;
	if (fraction < 0.5) return low;
	if (fraction > 0.5) return low + 1.0;
	return if (@mod(@as(i64, @intFromFloat(low)), 2) == 0) low else low + 1.0;
}

export fn gauss_elimination(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
	if (input == null or length < 1 or input[0] < 2 or input[0] > 8) return -1;
	const n: usize = @intCast(input[0]);
	if (length != 1+n*n+n) return -1;
	for (1..length) |i| if (input[i] < -100 or input[i] > 100) return -1;
	var m: [72]f32 = @splat(0);
	for (0..n) |r| { for (0..n) |c| m[r*9+c]=@floatFromInt(input[1+r*n+c]); m[r*9+n]=@floatFromInt(input[1+n*n+r]); }
	for (0..n-1) |i| {
		var pivot=i;
		for (i..n) |j| if (@abs(m[j*9+i]) > @abs(m[pivot*9+i])) { pivot=j; };
		if (m[pivot*9+i] == 0) return -1;
		if (pivot != i) for (0..n+1) |l| { const t=m[i*9+l]; m[i*9+l]=m[pivot*9+l]; m[pivot*9+l]=t; };
		for (i+1..n) |j| {
			const tmp = -(m[j*9+i]/m[i*9+i]);
			for (0..n+1) |l| m[j*9+l]=m[j*9+l]+m[i*9+l]*tmp;
		}
	}
	if (m[(n-1)*9+n-1] == 0) return -1;
	if (output == null or capacity < n*8) return -2;
	var ans: [8]f32 = @splat(0);
	for (0..n) |q| {
		const k=n-1-q;
		var mul: f32=0;
		var l=n;
		while (l > k+1) { l-=1; mul=mul+m[k*9+l]*ans[l]; }
		ans[k]=(m[k*9+n]-mul)/m[k*9+k];
	}
	for (0..n) |i| put_f64_le(output, i*8, round_even(@as(f64, ans[i])*100.0)/100.0);
	return @intCast(n*8);
}
