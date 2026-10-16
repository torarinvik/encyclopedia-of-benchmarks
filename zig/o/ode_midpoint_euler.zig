const max_steps: i64 = 8;
const output_bytes: usize = 16;

fn putF64Le(output: [*c]u8, offset: usize, value: f64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn ode_midpoint_euler(input: [*c]const i64, length: usize,
                             output: [*c]u8, capacity: usize) i64 {
    if (input == null or length != 4) return -1;
    const steps = input[0];
    const dt_quarters = input[1];
    const u0 = input[2];
    const v0 = input[3];
    if (steps < 1 or steps > max_steps or dt_quarters < 1 or dt_quarters > 4 or
        u0 < -10 or u0 > 10 or v0 < -10 or v0 > 10) return -1;
    if (output == null or capacity < output_bytes) return -2;

    const dt = @as(f64, @floatFromInt(dt_quarters)) / 4.0;
    const half_dt = 0.5 * dt;
    var u: f64 = @floatFromInt(u0);
    var v: f64 = @floatFromInt(v0);
    var step: i64 = 0;
    while (step < steps) : (step += 1) {
        const midpoint_u = u + half_dt * v;
        const midpoint_v = v - half_dt * u;
        const next_u = u + dt * midpoint_v;
        const next_v = v - dt * midpoint_u;
        u = next_u;
        v = next_v;
    }
    putF64Le(output, 0, u);
    putF64Le(output, 8, v);
    return @intCast(output_bytes);
}
