const PARTICLE_COUNT: usize = 50;
const DIMENSION_COUNT: usize = 5;
const ITERATION_COUNT: usize = 1000;
const MAX_INPUT_LENGTH: usize = 2;
const OUTPUT_VALUE_COUNT: usize = 1 + DIMENSION_COUNT + ITERATION_COUNT;
const OUTPUT_BYTES: usize = OUTPUT_VALUE_COUNT * 8;

fn nextUniform(state: *u64) f64 {
    var value = state.*;
    value ^= value << 13;
    value ^= value >> 7;
    value ^= value << 17;
    state.* = value;
    return @as(f64, @floatFromInt(value >> 11)) * 1.1102230246251565e-16;
}

fn sphere(point: *const [DIMENSION_COUNT]f64) f64 {
    var cost: f64 = 0.0;
    for (0..DIMENSION_COUNT) |coordinate| {
        cost += point[coordinate] * point[coordinate];
    }
    return cost;
}

fn writeF64Le(output: [*c]u8, offset: usize, value: f64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn particle_swarm_optimization(input: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length < 1 or length > MAX_INPUT_LENGTH or length != 1 or input[0] <= 0)
        return -1;
    if (output == null or output_capacity < OUTPUT_BYTES) return -2;

    var random_state: u64 = @intCast(input[0]);
    var positions: [PARTICLE_COUNT][DIMENSION_COUNT]f64 = undefined;
    var velocities: [PARTICLE_COUNT][DIMENSION_COUNT]f64 = undefined;
    var personal_positions: [PARTICLE_COUNT][DIMENSION_COUNT]f64 = undefined;
    var personal_costs: [PARTICLE_COUNT]f64 = undefined;
    var global_position: [DIMENSION_COUNT]f64 = [_]f64{0.0} ** DIMENSION_COUNT;
    var history: [ITERATION_COUNT]f64 = undefined;
    var global_cost: f64 = 1.7976931348623157e308;

    for (0..PARTICLE_COUNT) |particle| {
        for (0..DIMENSION_COUNT) |coordinate| {
            positions[particle][coordinate] = -10.0 + 20.0 * nextUniform(&random_state);
            velocities[particle][coordinate] = 0.0;
            personal_positions[particle][coordinate] = positions[particle][coordinate];
        }
        personal_costs[particle] = sphere(&positions[particle]);
        if (personal_costs[particle] < global_cost) {
            global_cost = personal_costs[particle];
            global_position = personal_positions[particle];
        }
    }

    var inertia: f64 = 1.0;
    for (0..ITERATION_COUNT) |iteration| {
        for (0..PARTICLE_COUNT) |particle| {
            var personal_random: [DIMENSION_COUNT]f64 = undefined;
            var social_random: [DIMENSION_COUNT]f64 = undefined;
            for (0..DIMENSION_COUNT) |coordinate| {
                personal_random[coordinate] = nextUniform(&random_state);
            }
            for (0..DIMENSION_COUNT) |coordinate| {
                social_random[coordinate] = nextUniform(&random_state);
            }

            for (0..DIMENSION_COUNT) |coordinate| {
                const cognitive = (2.0 * personal_random[coordinate]) *
                    (personal_positions[particle][coordinate] - positions[particle][coordinate]);
                const social = (2.0 * social_random[coordinate]) *
                    (global_position[coordinate] - positions[particle][coordinate]);
                velocities[particle][coordinate] = inertia * velocities[particle][coordinate] + cognitive + social;
                positions[particle][coordinate] += velocities[particle][coordinate];
            }

            const cost = sphere(&positions[particle]);
            if (cost < personal_costs[particle]) {
                personal_costs[particle] = cost;
                personal_positions[particle] = positions[particle];
                if (personal_costs[particle] < global_cost) {
                    global_cost = personal_costs[particle];
                    global_position = personal_positions[particle];
                }
            }
        }
        history[iteration] = global_cost;
        inertia *= 0.99;
    }

    var offset: usize = 0;
    writeF64Le(output, offset, global_cost);
    offset += 8;
    for (global_position) |value| {
        writeF64Le(output, offset, value);
        offset += 8;
    }
    for (history) |value| {
        writeF64Le(output, offset, value);
        offset += 8;
    }
    return @intCast(OUTPUT_BYTES);
}
