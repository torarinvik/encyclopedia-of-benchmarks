const MAX_N: usize = 24;
const MAX_RUNS: usize = 144;

const Run = struct { period: usize, left: usize, right: usize };

fn storeI64Le(output: [*c]u8, offset: usize, value: i64) void {
	const bits: u64 = @bitCast(value);
	for (0..8) |byte| output[offset + byte] = @intCast((bits >> @intCast(byte * 8)) & 0xff);
}

export fn runenumerate(input: [*c]const i64, length: usize,
	output: [*c]u8, capacity: usize) i64 {
	if (input == null or length < 2 or length > MAX_N + 1) return -1;
	const n_value = input[0];
	if (n_value < 1 or n_value > @as(i64, @intCast(MAX_N)) or length != @as(usize, @intCast(n_value)) + 1) return -1;
	const n: usize = @intCast(n_value);
	var text: [MAX_N]usize = .{0} ** MAX_N;
	for (0..n) |i| {
		const value = input[i + 1];
		if (value < 0 or value >= 26) return -1;
		text[i] = @intCast(value);
	}
	if (output == null) return -2;

	const stride = MAX_N + 1;
	var lcp: [stride * stride]usize = .{0} ** (stride * stride);
	var i = n;
	while (i > 0) {
		i -= 1;
		var j = n;
		while (j > i + 1) {
			j -= 1;
			if (text[i] == text[j]) lcp[i * stride + j] = 1 + lcp[(i + 1) * stride + j + 1];
		}
	}
	var runs: [MAX_RUNS]Run = undefined;
	var count: usize = 0;
	var period: usize = 1;
	while (period <= n / 2) : (period += 1) {
		var at = period;
		while (at < n) {
			if (text[at] != text[at - period]) { at += 1; continue; }
			const first = at;
			while (at < n and text[at] == text[at - period]) : (at += 1) {}
			const left = first - period;
			const right = at;
			if (right - left < 2 * period) continue;
			var minimal = true;
			var smaller: usize = 1;
			while (smaller < period) : (smaller += 1) {
				if (lcp[left * stride + left + smaller] >= right - left - smaller) {
					minimal = false;
					break;
				}
			}
			if (minimal and count < MAX_RUNS) {
				runs[count] = .{ .period = period, .left = left, .right = right };
				count += 1;
			}
		}
	}
	var sort_i: usize = 1;
	while (sort_i < count) : (sort_i += 1) {
		const value = runs[sort_i];
		var j = sort_i;
		while (j > 0) {
			const prev = runs[j - 1];
			const after = prev.period > value.period or
				(prev.period == value.period and prev.left > value.left) or
				(prev.period == value.period and prev.left == value.left and prev.right > value.right);
			if (!after) break;
			runs[j] = prev;
			j -= 1;
		}
		runs[j] = value;
	}
	const needed = 8 + 24 * count;
	if (capacity < needed) return -2;
	storeI64Le(output, 0, @intCast(count));
	for (0..count) |k| {
		const offset = 8 + 24 * k;
		storeI64Le(output, offset, @intCast(runs[k].period));
		storeI64Le(output, offset + 8, @intCast(runs[k].left));
		storeI64Le(output, offset + 16, @intCast(runs[k].right));
	}
	return @intCast(needed);
}
