// Clean-room bounded port of TSVC s162; see package README for provenance.
const MAX_N: usize = 64;
const MAX_INPUT_LENGTH: usize = 194;

fn storeI64Le(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn tsvc_s162_guarded_shifted_fma(input: [*c]const i64, length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 5 or length > MAX_INPUT_LENGTH) return -1;
    const values = input[0..length];
    if (values[0] < 1 or values[0] > @as(i64, @intCast(MAX_N)) or
        values[1] < 0 or values[1] > 1) return -1;
    const n: usize = @intCast(values[0]);
    if (length != 2 + 3 * n) return -1;
    for (values[2..]) |value| {
        if (value < -2 or value > 2) return -1;
    }
    if (output == null or capacity < 8 * n) return -2;
    const a_offset = 2;
    const b_offset = a_offset + n;
    const c_offset = b_offset + n;
    for (0..n) |i| storeI64Le(output, 8 * i, values[a_offset + i]);
    if (values[1] > 0) {
        for (0..n - 1) |i| {
            const value = values[a_offset + i + 1] + values[b_offset + i] * values[c_offset + i];
            storeI64Le(output, 8 * i, value);
        }
    }
    return @intCast(n);
}
