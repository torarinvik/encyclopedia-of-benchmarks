// Clean-room implementation of TSVC s293; see package rights note.
const MAX_N: usize = 32;

fn storeI64Le(out: [*c]u8, pos: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |b| out[pos + b] = @truncate(bits >> @intCast(8*b));
}

pub export fn tsvc_s293_first_element_broadcast(input: [*c]const i64,
    length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 2 or length > 33) return -1;
    const raw_n = input[0];
    if (raw_n < 1 or raw_n > MAX_N or length != 1 + @as(usize, @intCast(raw_n))) return -1;
    const n: usize = @intCast(raw_n);
    for (1..length) |i| if (input[i] < -8 or input[i] > 8) return -1;
    const bytes = 8*n;
    if (output == null or capacity < bytes) return -2;
    var staged = [_]i64{0} ** MAX_N;
    for (0..n) |i| staged[i] = input[1];
    for (0..n) |i| storeI64Le(output, 8*i, staged[i]);
    return @intCast(bytes);
}
