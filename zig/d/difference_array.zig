fn putI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn difference_array(input: ?[*]const i64, length: usize, output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 2) return -1;
    const values = input.?[0..length];
    const raw_n = values[0];
    const raw_q = values[1];
    if (raw_n < 1 or raw_n > 64 or raw_q < 0 or raw_q > 64) return -1;
    const n: usize = @intCast(raw_n);
    const q: usize = @intCast(raw_q);
    if (length != 2 + n + 3 * q) return -1;
    for (values[2..2+n]) |value| if (value < -1_000_000 or value > 1_000_000) return -1;
    for (0..q) |u| {
        const base = 2+n+3*u;
        if (values[base] < 0 or values[base] >= raw_n or values[base+1] < values[base] or values[base+1] >= raw_n or
            values[base+2] < -1_000_000 or values[base+2] > 1_000_000) return -1;
    }
    const bytes = n * 8;
    if (output == null or capacity < bytes) return -2;
    var diff: [65]i64 = @splat(0);
    diff[0] = values[2];
    for (1..n) |i| diff[i] = values[2+i] - values[2+i-1];
    for (0..q) |u| {
        const base = 2+n+3*u;
        const left: usize = @intCast(values[base]);
        const right: usize = @intCast(values[base+1]);
        const delta = values[base+2];
        diff[left] += delta;
        diff[right+1] -= delta;
    }
    const result = output.?[0..bytes];
    var current = diff[0];
    putI64Le(result.ptr, 0, current);
    for (1..n) |i| {
        current += diff[i];
        putI64Le(result.ptr, i*8, current);
    }
    return @intCast(bytes);
}
