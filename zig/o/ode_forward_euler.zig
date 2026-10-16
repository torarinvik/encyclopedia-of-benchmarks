fn storeF64Le(output: [*c]u8, offset: usize, value: f64) void {
    var bits: u64 = @bitCast(value);
    for (0..8) |byte| {
        output[offset + byte] = @intCast(bits & 255);
        bits >>= 8;
    }
}

export fn ode_forward_euler(values: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (values == null or length != 4) return -1;
    if (values[0] < 1 or values[0] > 16 or values[1] < 1 or values[1] > 4 or
        values[2] < -10 or values[2] > 10 or values[3] < -10 or values[3] > 10) return -1;
    if (output == null or output_capacity < 16) return -2;
    const dt: f64 = @as(f64, @floatFromInt(values[1])) / 4.0;
    var u: f64 = @floatFromInt(values[2]);
    var v: f64 = @floatFromInt(values[3]);
    for (0..@intCast(values[0])) |_| {
        const old_u = u;
        const old_v = v;
        u = old_u + dt * old_v;
        v = old_v - dt * old_u;
    }
    storeF64Le(output, 0, u);
    storeF64Le(output, 8, v);
    return 16;
}
