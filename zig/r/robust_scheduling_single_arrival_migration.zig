const MaxMachines: usize = 3;
const MaxOldJobs: usize = 8;
const MaxInput: usize = 20;
const MaxOutput: usize = 88;

fn put64(output: [*]u8, offset: usize, value: i64) void {
	const bits: u64 = @bitCast(value);
	for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

fn exactOptimum(machines: usize, sizes: *const [9]i64, jobs: usize) i64 {
	var assignments: usize = 1;
	for (0..jobs) |_| assignments *= machines;
	var best: i64 = 0;
	for (0..jobs) |i| best += sizes.*[i];
	for (0..assignments) |code| {
		var loads: [MaxMachines]i64 = @splat(0);
		var remaining = code;
		for (0..jobs) |j| {
			const target = remaining % machines;
			remaining /= machines;
			loads[target] += sizes.*[j];
		}
		var makespan = loads[0];
		for (1..machines) |machine| if (loads[machine] > makespan) { makespan = loads[machine]; };
		if (makespan < best) best = makespan;
	}
	return best;
}

export fn robust_scheduling_single_arrival_migration(input_opt: ?[*]const i64, length: usize,
	output_opt: ?[*]u8, capacity: usize) i64 {
	if (input_opt == null or length < 6 or length > MaxInput) return -1;
	const input = input_opt.?;
	const m64, const n64, const claimed, const new_size = .{ input[0], input[1], input[2], input[3] };
	if (m64 < 2 or m64 > 3 or n64 < 1 or n64 > 8 or claimed < 1 or new_size < 1 or new_size > 20 or length != 4 + 2 * @as(usize, @intCast(n64))) return -1;
	const machines: usize = @intCast(m64);
	const n: usize = @intCast(n64);
	var sizes: [9]i64 = @splat(0);
	var assignment: [9]usize = @splat(0);
	var loads: [MaxMachines]i64 = @splat(0);
	for (0..n) |i| {
		const size, const machine = .{ input[4 + 2 * i], input[5 + 2 * i] };
		if (size < 1 or size > 20 or machine < 0 or machine >= m64) return -1;
		sizes[i] = size;
		assignment[i] = @intCast(machine);
		loads[@intCast(machine)] += size;
	}
	sizes[n] = new_size;
	const optimum = exactOptimum(machines, &sizes, n + 1);
	if (claimed != optimum) return -1;
	var moved: i64 = 0;
	if (2 * new_size <= optimum) {
		var target: usize = 0;
		for (1..machines) |machine| if (loads[machine] < loads[target]) { target = machine; };
		assignment[n] = target;
		loads[target] += new_size;
	} else {
		var source: ?usize = null;
		for (0..machines) |machine| {
			var eligible = true;
			var volume: i64 = 0;
			for (0..n) |i| if (assignment[i] == machine) {
				if (2 * sizes[i] > optimum) eligible = false;
				volume += sizes[i];
			};
			if (eligible and volume >= new_size) { source = machine; break; }
		}
		if (source == null) return -1;
		const chosen = source.?;
		var removed: [MaxOldJobs]bool = @splat(false);
		var volume: i64 = 0;
		for (0..n) |i| {
			if (assignment[i] == chosen) {
				removed[i] = true;
				volume += sizes[i];
				loads[chosen] -= sizes[i];
				if (volume >= new_size) break;
			}
		}
		if (volume < new_size) return -1;
		assignment[n] = chosen;
		loads[chosen] += new_size;
		for (0..n) |i| if (removed[i]) {
			var target: usize = 0;
			for (1..machines) |machine| if (loads[machine] < loads[target]) { target = machine; };
			assignment[i] = target;
			loads[target] += sizes[i];
			if (target != chosen) moved += sizes[i];
		};
	}
	const bytes = 8 * (n + 3);
	if (output_opt == null or capacity < bytes) return -2;
	var staged: [MaxOutput]u8 = @splat(0);
	put64(&staged, 0, optimum);
	put64(&staged, 8, moved);
	for (0..n + 1) |i| put64(&staged, 8 * (i + 2), @intCast(assignment[i]));
	const output = output_opt.?;
	@memcpy(output[0..bytes], staged[0..bytes]);
	return @intCast(bytes);
}
