const MAX_D: usize = 4;
const MAX_N: usize = 16;
const MAX_L: usize = 4;
const MAX_INPUT: usize = 318;
const Q24: i64 = 16_777_216;

fn roundAway(numerator: i64, denominator: i64) i64 {
    const magnitude = if (numerator < 0) -numerator else numerator;
    var quotient = @divTrunc(magnitude, denominator);
    const remainder = @rem(magnitude, denominator);
    if (2 * remainder >= denominator) quotient += 1;
    return if (numerator < 0) -quotient else quotient;
}

fn writeI64(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn bodytrack_annealed_particle_filter(input: [*c]const i64, length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 3 or length > MAX_INPUT) return -1;
    const d_value = input[0];
    const n_value = input[1];
    const layers_value = input[2];
    if (d_value < 1 or d_value > @as(i64, @intCast(MAX_D)) or
        n_value < 2 or n_value > @as(i64, @intCast(MAX_N)) or
        layers_value < 1 or layers_value > @as(i64, @intCast(MAX_L))) return -1;
    const d: usize = @intCast(d_value);
    const n: usize = @intCast(n_value);
    const layers: usize = @intCast(layers_value);
    const expected = 2 + d + 2 * layers + n * d + (layers - 1) * n * (d + 1);
    if (length != expected) return -1;

    const target_at: usize = 3;
    const beta_at = target_at + d;
    const sigma_at = beta_at + layers;
    const pose_at = sigma_at + layers - 1;
    const uniform_at = pose_at + n * d;
    const shock_at = uniform_at + (layers - 1) * n;
    var target: [MAX_D]i64 = @splat(0);
    var beta: [MAX_L]i64 = @splat(0);
    var sigma: [MAX_L - 1]i64 = @splat(0);
    for (0..d) |axis| {
        target[axis] = input[target_at + axis];
        if (target[axis] < -10000 or target[axis] > 10000) return -1;
    }
    for (0..layers) |layer| {
        beta[layer] = input[beta_at + layer];
        if (beta[layer] < 1 or beta[layer] > 8 or
            (layer > 0 and beta[layer] <= beta[layer - 1])) return -1;
    }
    for (0..layers - 1) |layer| {
        sigma[layer] = input[sigma_at + layer];
        if (sigma[layer] < 0 or sigma[layer] > 2000 or
            (layer > 0 and sigma[layer] > sigma[layer - 1])) return -1;
    }
    for (0..n * d) |item| {
        if (input[pose_at + item] < -10000 or input[pose_at + item] > 10000) return -1;
    }
    for (0..(layers - 1) * n) |item| {
        if (input[uniform_at + item] < 0 or input[uniform_at + item] >= Q24) return -1;
    }
    for (0..(layers - 1) * n * d) |item| {
        if (input[shock_at + item] < -3000 or input[shock_at + item] > 3000) return -1;
    }

    const required = 8 * d;
    if (output == null or capacity < required) return -2;
    var population: [2][MAX_N][MAX_D]i64 = @splat(@splat(@splat(0)));
    var weights: [MAX_N]i64 = @splat(0);
    var estimate: [MAX_D]i64 = @splat(0);
    for (0..n) |particle| {
        for (0..d) |axis| population[0][particle][axis] = input[pose_at + particle * d + axis];
    }
    var active: usize = 0;
    for (0..layers) |layer| {
        var total_weight: i64 = 0;
        for (0..n) |particle| {
            var squared_distance: i64 = 0;
            for (0..d) |axis| {
                const delta = population[active][particle][axis] - target[axis];
                squared_distance += delta * delta;
            }
            const energy = @divTrunc(squared_distance, 10000);
            const base = @divTrunc(Q24 * 100000, 100000 + energy);
            var weight = base;
            var power: i64 = 1;
            while (power < beta[layer]) : (power += 1) weight = @divTrunc(weight * base, Q24);
            weights[particle] = weight;
            total_weight += weight;
        }
        if (layer + 1 == layers) {
            for (0..d) |axis| {
                var moment: i64 = 0;
                for (0..n) |particle| moment += weights[particle] * population[active][particle][axis];
                estimate[axis] = roundAway(moment, total_weight);
            }
            break;
        }
        const destination = 1 - active;
        for (0..n) |child| {
            const draw = input[uniform_at + layer * n + child];
            const threshold = @divTrunc(draw * total_weight, Q24);
            var cumulative: i64 = 0;
            var ancestor: usize = 0;
            while (cumulative <= threshold) : (ancestor += 1) cumulative += weights[ancestor];
            ancestor -= 1;
            for (0..d) |axis| {
                const shock = input[shock_at + layer * n * d + child * d + axis];
                const movement = roundAway(sigma[layer] * shock, 1000);
                const coordinate = population[active][ancestor][axis] + movement;
                population[destination][child][axis] = @max(-10000, @min(10000, coordinate));
            }
        }
        active = destination;
    }
    for (0..d) |axis| writeI64(output, 8 * axis, estimate[axis]);
    return @intCast(required);
}
