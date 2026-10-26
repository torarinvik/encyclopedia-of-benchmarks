const max_n: usize = 32;
const max_input: usize = 33;
const capacity_per_bin: i64 = 10000;

fn storeI64LE(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn harmonic_4_bin_packing(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > max_input) return -1;
    const input = input_opt.?;
    const n64 = input[0];
    if (n64 < 1 or n64 > 32 or length != 1 + @as(usize, @intCast(n64))) return -1;
    const n: usize = @intCast(n64);
    for (0..n) |i| if (input[1 + i] < 1 or input[1 + i] > capacity_per_bin) return -1;
    const output_bytes = 8 * (n + 1);
    if (output_opt == null or capacity < output_bytes) return -2;
    const output = output_opt.?;
    var current: [4]i64 = [_]i64{-1} ** 4;
    var remaining: [4]i64 = [_]i64{0} ** 4;
    var assignment: [max_n]i64 = [_]i64{0} ** max_n;
    var bins: i64 = 0;
    for (0..n) |i| {
        const size = input[1 + i];
        const kind: usize = if (size * 2 > capacity_per_bin) 0 else if (size * 3 > capacity_per_bin) 1
            else if (size * 4 > capacity_per_bin) 2 else 3;
        if (current[kind] < 0 or size > remaining[kind]) {
            current[kind] = bins;
            bins += 1;
            remaining[kind] = capacity_per_bin;
        }
        assignment[i] = current[kind];
        remaining[kind] -= size;
    }
    storeI64LE(output, 0, bins);
    for (0..n) |i| storeI64LE(output, 8 * (i + 1), assignment[i]);
    return @intCast(output_bytes);
}
