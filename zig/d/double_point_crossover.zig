fn put_i64_le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn double_point_crossover(input: [*]const i64, length: usize, output: [*]u8, capacity: usize) i64 {
    if (length < 7 or length > 131) return -1;
    const n = input[0]; const j1 = input[1]; const j2 = input[2];
    if (n < 2 or n > 64 or length != @as(usize, @intCast(3 + 2 * n)) or j1 < 1 or j1 >= j2 or j2 > n) return -1;
    for (0..@as(usize, @intCast(2 * n))) |i| if (input[3 + i] < -2147483648 or input[3 + i] > 2147483647) return -1;
    const count: usize = @intCast(n); const bytes = 16 * count;
    if (capacity < bytes) return -2;
    const a: usize = @intCast(j1); const b: usize = @intCast(j2);
    for (0..count) |i| {
        var child1 = input[3 + i]; var child2 = input[3 + count + i];
        if (i >= a and i < b) { const temp = child1; child1 = child2; child2 = temp; }
        put_i64_le(output, i * 8, child1); put_i64_le(output, (count + i) * 8, child2);
    }
    return @intCast(bytes);
}
