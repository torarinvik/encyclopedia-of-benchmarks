const std = @import("std");

const max_states: usize = 8;
const max_steps: usize = 64;
const max_input: usize = 140;

fn boundedInteger(value: f64, minimum: f64, maximum: f64) bool {
    return std.math.isFinite(value) and @trunc(value) == value and value >= minimum and value <= maximum;
}

export fn metropolis_mcmc(input_opt: ?[*]const f64, length: usize,
    output_opt: ?[*]f64, capacity: usize) i64 {
    if (input_opt == null or length < 4 or length > max_input) return -1;
    const input = input_opt.?;
    if (!boundedInteger(input[0], 1.0, @floatFromInt(max_states)) or
        !boundedInteger(input[1], 0.0, @floatFromInt(max_steps))) return -1;
    const states: usize = @intFromFloat(input[0]);
    const steps: usize = @intFromFloat(input[1]);
    if (!boundedInteger(input[2], 0.0, @floatFromInt(states - 1)) or
        !std.math.isFinite(input[3]) or input[3] < 0.001 or input[3] > 1000.0 or
        length != 4 + states + 2 * steps) return -1;
    for (0..states) |state| {
        const energy = input[4 + state];
        if (!std.math.isFinite(energy) or @abs(energy) > 1_000_000.0) return -1;
    }
    const proposal_start = 4 + states;
    const uniform_start = proposal_start + steps;
    for (0..steps) |step| {
        if (!boundedInteger(input[proposal_start + step], 0.0, @floatFromInt(states - 1))) return -1;
        const uniform = input[uniform_start + step];
        if (!std.math.isFinite(uniform) or uniform < 0.0 or uniform >= 1.0) return -1;
    }
    if (output_opt == null or capacity < steps + 1) return -2;
    const output = output_opt.?;

    var current: usize = @intFromFloat(input[2]);
    output[0] = @floatFromInt(current);
    for (0..steps) |step| {
        const proposal: usize = @intFromFloat(input[proposal_start + step]);
        const delta = (input[4 + proposal] - input[4 + current]) / input[3];
        if (delta <= 0.0) {
            current = proposal;
        } else if (input[uniform_start + step] < @exp(-delta)) {
            current = proposal;
        }
        output[step + 1] = @floatFromInt(current);
    }
    return @intCast(steps + 1);
}
