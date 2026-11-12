const std = @import("std");

const MAX_PARTICLES: usize = 32;
const MAX_INPUT_LENGTH: usize = 2 + 6 * MAX_PARTICLES;
const PI: f64 = 3.14159265358979323846264338327950288;

fn storeF64Le(output: [*]u8, offset: usize, value: f64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn fluidanimate_sph(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > MAX_INPUT_LENGTH) return -1;
    const input = input_opt.?;
    const count_value = input[0];
    const rpm_milli = input[1];
    if (count_value < 1 or count_value > @as(i64, @intCast(MAX_PARTICLES))
            or rpm_milli < 500 or rpm_milli > 5000) return -1;
    const count: usize = @intCast(count_value);
    if (length != 2 + 6 * count) return -1;
    for (0..count) |i| {
        const base = 2 + 6 * i;
        for (0..3) |axis| {
            if (input[base + axis] < -10000 or input[base + axis] > 10000
                    or input[base + 3 + axis] < -5000 or input[base + 3 + axis] > 5000) return -1;
        }
    }
    const output_bytes = 40 * count;
    if (output_opt == null or capacity < output_bytes) return -2;
    const output = output_opt.?;

    var position: [MAX_PARTICLES][3]f64 = @splat(@splat(0.0));
    var velocity: [MAX_PARTICLES][3]f64 = @splat(@splat(0.0));
    var acceleration: [MAX_PARTICLES][3]f64 = @splat(@splat(0.0));
    var density: [MAX_PARTICLES]f64 = @splat(0.0);
    const rpm = @as(f64, @floatFromInt(rpm_milli)) / 1000.0;
    const h = 1.695 / rpm;
    const h2 = h * h;
    const mass = 1000.0 / (rpm * rpm * rpm);
    const density_coeff = mass * (315.0 / (64.0 * PI * std.math.pow(f64, h, 9.0)));
    const pressure_coeff = 3.0 * (15.0 / (PI * std.math.pow(f64, h, 6.0))) * 1.5 * mass;
    const viscosity_coeff = 0.4 * (45.0 / (PI * std.math.pow(f64, h, 6.0))) * mass;
    for (0..count) |i| {
        const base = 2 + 6 * i;
        for (0..3) |axis| {
            position[i][axis] = @as(f64, @floatFromInt(input[base + axis])) / 1000.0;
            velocity[i][axis] = @as(f64, @floatFromInt(input[base + 3 + axis])) / 1000.0;
            acceleration[i][axis] = if (axis == 1) -9.8 else 0.0;
        }
        density[i] = density_coeff * h2 * h2 * h2;
    }
    for (0..count) |i| {
        for (i + 1..count) |j| {
            const dx = position[i][0] - position[j][0];
            const dy = position[i][1] - position[j][1];
            const dz = position[i][2] - position[j][2];
            const r2 = dx * dx + dy * dy + dz * dz;
            if (r2 < h2) {
                const term = density_coeff * std.math.pow(f64, h2 - r2, 3.0);
                density[i] += term;
                density[j] += term;
            }
        }
    }
    for (0..count) |i| {
        for (i + 1..count) |j| {
            const disp = [3]f64{position[i][0] - position[j][0],
                position[i][1] - position[j][1], position[i][2] - position[j][2]};
            const r2 = disp[0] * disp[0] + disp[1] * disp[1] + disp[2] * disp[2];
            if (r2 >= h2) continue;
            const distance = @sqrt(@max(r2, 1e-12));
            const hmr = h - distance;
            const rho_product = density[i] * density[j];
            const pressure_scale = pressure_coeff * (hmr * hmr / distance)
                * (density[i] + density[j] - 2000.0) / rho_product;
            const viscosity_scale = viscosity_coeff * hmr / rho_product;
            for (0..3) |axis| {
                const force = disp[axis] * pressure_scale
                    + (velocity[j][axis] - velocity[i][axis]) * viscosity_scale;
                acceleration[i][axis] += force;
                acceleration[j][axis] -= force;
            }
        }
    }
    for (0..count) |i| {
        const fields = [5]f64{density[i], 3.0 * (density[i] - 1000.0),
            acceleration[i][0], acceleration[i][1], acceleration[i][2]};
        for (0..5) |field| storeF64Le(output, 8 * (5 * i + field), fields[field]);
    }
    return @intCast(output_bytes);
}
