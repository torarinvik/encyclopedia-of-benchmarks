fn putF64Le(output: [*]u8, offset: usize, value: f64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn damped_oscillator(input: ?[*]const i64, length: usize, output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length != 5) return -1;
    const values = input.?[0..length];
    if (values[0] < 1 or values[0] > 1024 or values[1] < 0 or values[1] > 1024 or
        values[2] < -1024 or values[2] > 1024 or values[3] < -1024 or values[3] > 1024 or
        values[4] < 1 or values[4] > 1024) return -1;
    if (output == null or capacity < 16) return -2;
    const omega0 = @as(f64, @floatFromInt(values[0])) / 1024.0;
    const gamma = @as(f64, @floatFromInt(values[1])) / 1024.0;
    const x = @as(f64, @floatFromInt(values[2])) / 1024.0;
    const v = @as(f64, @floatFromInt(values[3])) / 1024.0;
    const dt = @as(f64, @floatFromInt(values[4])) / 1024.0;
    const acceleration = -2.0 * gamma * v - omega0 * omega0 * x;
    const x_next = x + dt * v;
    const v_next = v + dt * acceleration;
    const result = output.?[0..16];
    putF64Le(result.ptr, 0, x_next);
    putF64Le(result.ptr, 8, v_next);
    return 16;
}
