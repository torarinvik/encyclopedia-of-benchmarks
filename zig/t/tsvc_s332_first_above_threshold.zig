// Clean-room bounded port of TSVC s332; see package README for provenance.
const MAX_N: usize = 256;
const MAX_INPUT_LENGTH: usize = 258;

fn storeI64Le(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn tsvc_s332_first_above_threshold(input: [*c]const i64, length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 3 or length > MAX_INPUT_LENGTH) return -1;
    const values = input[0..length];
    if (values[0] < 1 or values[0] > @as(i64, @intCast(MAX_N)) or
        values[1] < -1000000 or values[1] > 1000000) return -1;
    const n: usize = @intCast(values[0]);
    const threshold = values[1];
    if (length != 2 + n) return -1;
    var items = [_]i64{0} ** MAX_N;
    for (0..n) |i| {
        items[i] = values[2 + i];
        if (items[i] < -1000000 or items[i] > 1000000) return -1;
    }
    if (output == null or capacity < 16) return -2;
    var index: i64 = -2;
    var value: i64 = -1;
    for (0..n) |i| {
        if (items[i] > threshold) {
            index = @intCast(i);
            value = items[i];
            break;
        }
    }
    storeI64Le(output, 0, index);
    storeI64Le(output, 8, value);
    return 2;
}
