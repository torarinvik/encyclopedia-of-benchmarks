// Clean-room bounded port of TSVC s4114; see package README for provenance.
const MAX_N: usize = 64;
const MAX_INPUT_LENGTH: usize = 257;

fn storeI64Le(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn tsvc_s4114_reverse_index_gather_fma(input: [*c]const i64, length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 5 or length > MAX_INPUT_LENGTH) return -1;
    const values = input[0..length];
    if (values[0] < 1 or values[0] > @as(i64, @intCast(MAX_N))) return -1;
    const n: usize = @intCast(values[0]);
    if (length != 1 + 4 * n) return -1;
    const ip_offset = 1;
    const b_offset = 1 + n;
    const c_offset = 1 + 2 * n;
    const d_offset = 1 + 3 * n;
    for (0..n) |i| {
        if (values[ip_offset + i] < 0 or values[ip_offset + i] >= @as(i64, @intCast(n))) return -1;
        if (values[b_offset + i] < -2 or values[b_offset + i] > 2 or
            values[c_offset + i] < -2 or values[c_offset + i] > 2 or
            values[d_offset + i] < -2 or values[d_offset + i] > 2) return -1;
    }
    if (output == null or capacity < 8 * n) return -2;
    for (0..n) |i| {
        const gathered = n - 1 - @as(usize, @intCast(values[ip_offset + i]));
        const value = values[b_offset + i] + values[c_offset + gathered] * values[d_offset + i];
        storeI64Le(output, 8 * i, value);
    }
    return @intCast(n);
}
