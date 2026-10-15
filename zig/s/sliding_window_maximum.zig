const MAX_LENGTH: usize = 1024;
fn storeI64Le(out: [*]u8, offset: usize, value: i64) void { const bits: u64 = @bitCast(value); for (0..8) |b| out[offset + b] = @truncate(bits >> (8 * b)); }

export fn sliding_window_maximum(raw: [*]const i64, length: usize, output: ?[*]u8, capacity: usize) i64 {
    if (length < 2 or length > MAX_LENGTH + 2) return -1;
    const input = raw[0..length];
    if (input[0] < 0 or input[0] > MAX_LENGTH or input[1] < 1 or input[1] > MAX_LENGTH) return -1;
    const n: usize = @intCast(input[0]); const k: usize = @intCast(input[1]);
    if (length != n + 2) return -1;
    for (input[2..]) |value| if (value < -2147483648 or value > 2147483647) return -1;
    const windows = if (n >= k) n - k + 1 else 0;
    if (capacity < windows * 8) return -2;
    const out = if (output) |ptr| ptr else { if (windows == 0) return 0; return -2; };
    var deque: [MAX_LENGTH]usize = @splat(0); var head: usize = 0; var tail: usize = 0; var out_index: usize = 0;
    for (0..n) |i| {
        while (head < tail and deque[head] + k <= i) head += 1;
        while (head < tail and input[2 + deque[tail - 1]] < input[2 + i]) tail -= 1;
        deque[tail] = i; tail += 1;
        if (i + 1 >= k) { storeI64Le(out, out_index * 8, input[2 + deque[head]]); out_index += 1; }
    }
    return @intCast(windows);
}
