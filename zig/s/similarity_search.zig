fn putU64(out: [*]u8, offset: usize, value: u64) void {
    for (0..8) |b| out[offset + b] = @truncate(value >> @intCast(8 * b));
}
fn putI64(out: [*]u8, offset: usize, value: i64) void { putU64(out, offset, @bitCast(value)); }
fn putF64(out: [*]u8, offset: usize, value: f64) void { putU64(out, offset, @bitCast(value)); }

export fn similarity_search(input: ?[*]const i64, length: usize, output: ?[*]u8, output_capacity: usize) i64 {
    if (input == null or length < 3 or length > 643) return -1;
    const values = input.?;
    const rv, qv, fv = .{ values[0], values[1], values[2] };
    if (rv < 1 or rv > 32 or qv < 1 or qv > 8 or fv < 1 or fv > 16) return -1;
    const rows: usize = @intCast(rv); const queries: usize = @intCast(qv); const features: usize = @intCast(fv);
    if (length != 3 + (rows + queries) * features) return -1;
    for (0..(rows + queries) * features) |i| if (values[3 + i] < -1000000 or values[3 + i] > 1000000) return -1;
    const record = 16 + 8 * features;
    const needed = queries * record;
    if (output == null or output_capacity < needed) return -2;
    const out = output.?;
    for (0..queries) |query| {
        var best: usize = 0;
        var sum: f64 = 0;
        for (0..features) |f| {
            const delta = @as(f64, @floatFromInt(values[3 + f])) / 1000000.0 -
                @as(f64, @floatFromInt(values[3 + rows * features + query * features + f])) / 1000000.0;
            sum += delta * delta;
        }
        var best_distance = @sqrt(sum);
        for (1..rows) |row| {
            sum = 0;
            for (0..features) |f| {
                const delta = @as(f64, @floatFromInt(values[3 + row * features + f])) / 1000000.0 -
                    @as(f64, @floatFromInt(values[3 + rows * features + query * features + f])) / 1000000.0;
                sum += delta * delta;
            }
            const distance = @sqrt(sum);
            if (distance < best_distance) { best = row; best_distance = distance; }
        }
        const base = query * record;
        putI64(out, base, @intCast(best));
        putF64(out, base + 8, best_distance);
        for (0..features) |f| putI64(out, base + 16 + 8 * f, values[3 + best * features + f]);
    }
    return @intCast(needed);
}
