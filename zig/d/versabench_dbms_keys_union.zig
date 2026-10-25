const MAX_COUNT: usize = 16;
const MAX_INPUT_LENGTH: usize = 1 + 8 * MAX_COUNT;

fn writeI64Le(output: [*]u8, index: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |b| output[index * 8 + b] = @truncate(bits >> @intCast(8 * b));
}

export fn versabench_dbms_keys_union(raw: ?[*]const i64, length: usize,
    raw_output: ?[*]u8, output_capacity: usize) i64 {
    if (raw == null or length < 1 or length > MAX_INPUT_LENGTH + 1) return -1;
    const values = raw.?[0..length];
    const raw_count = values[0];
    if (raw_count < 1 or raw_count > @as(i64, MAX_COUNT) or length != 1 + 8 * @as(usize, @intCast(raw_count))) return -1;
    var bounds: [8]i64 = undefined;
    for (0..4) |d| { bounds[d] = values[1+d]; bounds[4+d] = values[5+d]; }
    for (0..@as(usize, @intCast(raw_count))) |i| {
        const at = 1 + 8 * i;
        for (0..4) |d| {
            const lo = values[at+d]; const hi = values[at+4+d];
            if (lo < -8 or lo > 8 or hi < -8 or hi > 8 or lo > hi) return -1;
            bounds[d] = @min(bounds[d], lo); bounds[4+d] = @max(bounds[4+d], hi);
        }
    }
    if (raw_output == null or output_capacity < 64) return -2;
    const output = raw_output.?;
    for (0..8) |i| writeI64Le(output, i, bounds[i]);
    return 64;
}
