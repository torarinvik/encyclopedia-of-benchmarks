const MaxN: usize = 12;
const MaxPairs: usize = 36;
const TableValues: usize = 234;
const MaxInput: usize = 247;
const MaxOutput: usize = 112;
const Inf: i64 = 1 << 60;

fn pairType(a: i64, b: i64) i32 {
	if (a == 0 and b == 3) return 0;
	if (a == 3 and b == 0) return 1;
	if (a == 1 and b == 2) return 2;
	if (a == 2 and b == 1) return 3;
	if (a == 2 and b == 3) return 4;
	if (a == 3 and b == 2) return 5;
	return -1;
}

fn lexLessMask(left: u64, right: u64, count: usize) bool {
	var li: usize = 0;
	var ri: usize = 0;
	while (true) {
		while (li < count and ((left >> @intCast(li)) & 1) == 0) : (li += 1) {}
		while (ri < count and ((right >> @intCast(ri)) & 1) == 0) : (ri += 1) {}
		if (li == count or ri == count) return li == count and ri < count;
		if (li != ri) return li < ri;
		li += 1;
		ri += 1;
	}
}

fn loopCost(input: [*]const i64, n: usize, kind: i32, unpaired: usize, children: usize) i64 {
	return input[1 + n + @as(usize, @intCast(kind)) * 39 + unpaired * 3 + children];
}

fn put64(out: [*]u8, offset: usize, value: i64) void {
	const bits: u64 = @bitCast(value);
	for (0..8) |b| out[offset + b] = @truncate(bits >> @intCast(8 * b));
}

export fn rna_mfe_loop_energy_dp(input_opt: ?[*]const i64, length: usize,
	output_opt: ?[*]u8, capacity: usize) i64 {
	if (input_opt == null or length < 239 or length > MaxInput) return -1;
	const input = input_opt.?;
	const n64 = input[0];
	if (n64 < 4 or n64 > 12 or length != 1 + @as(usize, @intCast(n64)) + TableValues) return -1;
	const n: usize = @intCast(n64);
	var bases: [MaxN]i64 = @splat(0);
	for (0..n) |i| { bases[i] = input[1 + i]; if (bases[i] < 0 or bases[i] > 3) return -1; }
	for (1 + n..length) |i| if (input[i] < -1000 or input[i] > 1000) return -1;
	var types: [MaxN][MaxN]i32 = @splat(@splat(-1));
	var ids: [MaxN][MaxN]i32 = @splat(@splat(-1));
	var pair_i: [MaxPairs]usize = @splat(0);
	var pair_j: [MaxPairs]usize = @splat(0);
	var pair_count: usize = 0;
	for (0..n) |i| {
		for (i + 4..n) |j| {
			const kind = pairType(bases[i], bases[j]);
			if (kind >= 0) { types[i][j] = kind; ids[i][j] = @intCast(pair_count); pair_i[pair_count] = i; pair_j[pair_count] = j; pair_count += 1; }
		}
	}
	var ve: [MaxN][MaxN]i64 = @splat(@splat(Inf));
	var vm: [MaxN][MaxN]u64 = @splat(@splat(0));
	for (4..n) |span| {
		for (0..n - span) |i| {
			const j = i + span;
			const kind = types[i][j];
			if (kind < 0) continue;
			const outer = @as(u64, 1) << @intCast(ids[i][j]);
			var best: i64 = Inf;
			var best_mask: u64 = 0;
			var candidate = loopCost(input, n, kind, span - 1, 0);
			if (candidate < best or (candidate == best and lexLessMask(outer, best_mask, pair_count))) { best = candidate; best_mask = outer; }
			for (i + 1..j) |a| {
				for (a + 4..j) |b| {
					if (ids[a][b] < 0 or ve[a][b] == Inf) continue;
					const unpaired = a - i - 1 + j - b - 1;
					candidate = loopCost(input, n, kind, unpaired, 1) + ve[a][b];
					const mask = outer | vm[a][b];
					if (candidate < best or (candidate == best and lexLessMask(mask, best_mask, pair_count))) { best = candidate; best_mask = mask; }
				}
			}
			for (i + 1..j) |a| {
				for (a + 4..j) |b| {
					if (ids[a][b] < 0 or ve[a][b] == Inf) continue;
					for (b + 1..j) |c| {
						for (c + 4..j) |d| {
							if (ids[c][d] < 0 or ve[c][d] == Inf) continue;
							const unpaired = a - i - 1 + c - b - 1 + j - d - 1;
							candidate = loopCost(input, n, kind, unpaired, 2) + ve[a][b] + ve[c][d];
							const mask = outer | vm[a][b] | vm[c][d];
							if (candidate < best or (candidate == best and lexLessMask(mask, best_mask, pair_count))) { best = candidate; best_mask = mask; }
						}
					}
				}
			}
			ve[i][j] = best;
			vm[i][j] = best_mask;
		}
	}
	var we: [MaxN]i64 = @splat(0);
	var wm: [MaxN]u64 = @splat(0);
	for (0..n) |j| {
		var best: i64 = if (j == 0) 0 else we[j - 1];
		var best_mask: u64 = if (j == 0) 0 else wm[j - 1];
		if (j >= 4) {
			for (0..j - 3) |i| {
				if (types[i][j] < 0 or ve[i][j] == Inf) continue;
				const prefix: i64 = if (i == 0) 0 else we[i - 1];
				const prefix_mask: u64 = if (i == 0) 0 else wm[i - 1];
				const value = prefix + ve[i][j];
				const mask = prefix_mask | vm[i][j];
				if (value < best or (value == best and lexLessMask(mask, best_mask, pair_count))) { best = value; best_mask = mask; }
			}
		}
		we[j] = best;
		wm[j] = best_mask;
	}
	var count: usize = 0;
	for (0..pair_count) |p| if (((wm[n - 1] >> @intCast(p)) & 1) != 0) { count += 1; };
	const bytes = 8 * (2 + 2 * count);
	if (output_opt == null or capacity < bytes) return -2;
	var staged: [MaxOutput]u8 = @splat(0);
	put64(&staged, 0, we[n - 1]);
	put64(&staged, 8, @intCast(count));
	var at: usize = 2;
	for (0..pair_count) |p| {
		if (((wm[n - 1] >> @intCast(p)) & 1) != 0) { put64(&staged, 8 * at, @intCast(pair_i[p])); at += 1; put64(&staged, 8 * at, @intCast(pair_j[p])); at += 1; }
	}
	const output = output_opt.?;
	@memcpy(output[0..bytes], staged[0..bytes]);
	return @intCast(bytes);
}
