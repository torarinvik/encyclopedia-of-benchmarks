// Clean-room bounded port of TSVC s171; see package README for provenance.
const MAX_N: usize = 32;
const MAX_STRIDE: usize = 4;
const MAX_INPUT_LENGTH: usize = 159;

fn storeI64Le(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn tsvc_s171_stride_indexed_accumulate(input: [*c]const i64, length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 4 or length > MAX_INPUT_LENGTH) return -1;
    const values = input[0..length];
    if (values[0] < 1 or values[0] > @as(i64, @intCast(MAX_N)) or
        values[1] < 1 or values[1] > @as(i64, @intCast(MAX_STRIDE))) return -1;
    const n: usize = @intCast(values[0]);
    const stride: usize = @intCast(values[1]);
    const a_length = 1 + (n - 1) * stride;
    if (length != 2 + a_length + n) return -1;
    for (values[2..]) |value| {
        if (value < -8 or value > 8) return -1;
    }
    if (output == null or capacity < 8 * a_length) return -2;
    for (0..a_length) |i| storeI64Le(output, 8 * i, values[2 + i]);
    const b_offset = 2 + a_length;
    for (0..n) |i| {
        const destination = i * stride;
        storeI64Le(output, 8 * destination, values[2 + destination] + values[b_offset + i]);
    }
    return @intCast(a_length);
}
