// Clean-room bounded port of TSVC s4117; see package README for provenance.
const MAX_N: usize = 64;
const MAX_INPUT_LENGTH: usize = 161;

fn storeI64Le(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn tsvc_s4117_pair_replicated_gather_map(input: [*c]const i64, length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 4 or length > MAX_INPUT_LENGTH) return -1;
    const values = input[0..length];
    if (values[0] < 1 or values[0] > @as(i64, @intCast(MAX_N))) return -1;
    const n: usize = @intCast(values[0]);
    const c_length = (n + 1) / 2;
    if (length != 1 + 2 * n + c_length) return -1;
    for (values[1..]) |value| {
        if (value < -2 or value > 2) return -1;
    }
    if (output == null or capacity < 8 * n) return -2;
    const b_offset = 1;
    const c_offset = 1 + n;
    const d_offset = c_offset + c_length;
    for (0..n) |i| {
        const value = values[b_offset + i] + values[c_offset + i / 2] * values[d_offset + i];
        storeI64Le(output, 8 * i, value);
    }
    return @intCast(n);
}
