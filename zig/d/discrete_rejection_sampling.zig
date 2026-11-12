const MAX_CATEGORIES: usize = 8;
const MAX_SAMPLES: usize = 8;
const MAX_ATTEMPTS: usize = 32;
const MAX_INPUT_VALUES: usize = 83;

fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @as(u6, @intCast(byte * 8)));
}

export fn discrete_rejection_sampling(input: ?[*]const i64, length: usize,
    output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 3 or length > MAX_INPUT_VALUES) return -1;
    const values = input.?[0..length];
    const n_value = values[0];
    const samples_value = values[1];
    const attempts_value = values[2];
    if (n_value < 1 or n_value > MAX_CATEGORIES or samples_value < 1 or samples_value > MAX_SAMPLES or
        attempts_value < 1 or attempts_value > MAX_ATTEMPTS) return -1;
    const n: usize = @intCast(n_value);
    const wanted: usize = @intCast(samples_value);
    const attempts: usize = @intCast(attempts_value);
    if (length != 3 + 2 * n + 2 * attempts) return -1;

    var target: [MAX_CATEGORIES]u64 = @splat(0);
    var proposal: [MAX_CATEGORIES]u64 = @splat(0);
    var cumulative: [MAX_CATEGORIES]u64 = @splat(0);
    var target_total: u64 = 0;
    var proposal_total: u64 = 0;
    for (0..n) |i| {
        const weight = values[3 + i];
        const q_weight = values[3 + n + i];
        if (weight < 1 or weight > 20 or q_weight < 1 or q_weight > 20) return -1;
        target[i] = @intCast(weight);
        proposal[i] = @intCast(q_weight);
        target_total += target[i];
        proposal_total += proposal[i];
        cumulative[i] = proposal_total;
    }

    var envelope: u64 = 1;
    for (0..n) |i| {
        const numerator = target[i] * proposal_total;
        const denominator = target_total * proposal[i];
        const ratio_ceiling = @divTrunc(numerator + denominator - 1, denominator);
        envelope = @max(envelope, ratio_ceiling);
    }

    const tape_offset = 3 + 2 * n;
    for (0..attempts) |attempt| {
        const proposal_draw = values[tape_offset + 2 * attempt];
        const acceptance_draw = values[tape_offset + 2 * attempt + 1];
        if (proposal_draw < 0 or @as(u64, @intCast(proposal_draw)) >= proposal_total or acceptance_draw < 0) return -1;
        var category: usize = 0;
        while (cumulative[category] <= @as(u64, @intCast(proposal_draw))) category += 1;
        const acceptance_range = target_total * proposal[category] * envelope;
        if (@as(u64, @intCast(acceptance_draw)) >= acceptance_range) return -1;
    }

    const output_bytes = 16 * wanted;
    if (output == null or capacity < output_bytes) return -2;
    var staged: [2 * MAX_SAMPLES]i64 = @splat(0);
    var produced: usize = 0;
    var attempts_since_acceptance: usize = 0;
    for (0..attempts) |attempt| {
        attempts_since_acceptance += 1;
        const proposal_draw: u64 = @intCast(values[tape_offset + 2 * attempt]);
        const acceptance_draw: u64 = @intCast(values[tape_offset + 2 * attempt + 1]);
        var category: usize = 0;
        while (cumulative[category] <= proposal_draw) category += 1;
        if (acceptance_draw < @as(i64, @intCast(target[category] * proposal_total))) {
            staged[produced] = @intCast(category);
            staged[produced + 1] = @intCast(attempts_since_acceptance);
            produced += 2;
            attempts_since_acceptance = 0;
            if (produced == 2 * wanted) break;
        }
    }
    if (produced != 2 * wanted) return -3;
    const destination = output.?;
    for (0..produced) |i| storeI64Le(destination, 8 * i, staged[i]);
    return @intCast(output_bytes);
}
