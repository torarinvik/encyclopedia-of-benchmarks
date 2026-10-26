const MAX_ITEMS: usize = 5;
const MAX_ATOMS: usize = 3;
const MAX_INPUT: usize = 43;
const MAX_OUTPUT_WORDS: usize = 9;

fn store_i64_le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

fn density_before(left: usize, right: usize, reward: *const [MAX_ITEMS]i64,
    fit: *const [MAX_ITEMS]i64, mean: *const [MAX_ITEMS]i64) bool {
    const left_score = reward[left] * fit[left] * mean[right];
    const right_score = reward[right] * fit[right] * mean[left];
    return left_score > right_score or (left_score == right_score and left < right);
}

export fn stochastic_knapsack_greedy(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > MAX_INPUT) return -1;
    const input = input_opt.?;
    const n_raw = input[0];
    const bound_raw = input[1];
    if (n_raw < 1 or n_raw > @as(i64, MAX_ITEMS) or bound_raw < 1 or bound_raw > 8) return -1;
    const n: usize = @intCast(n_raw);
    const bound: i64 = bound_raw;
    var reward: [MAX_ITEMS]i64 = @splat(0);
    var atom_count: [MAX_ITEMS]usize = @splat(0);
    var denominator: [MAX_ITEMS]i64 = @splat(0);
    var fit: [MAX_ITEMS]i64 = @splat(0);
    var mean: [MAX_ITEMS]i64 = @splat(0);
    var sizes: [MAX_ITEMS][MAX_ATOMS]i64 = @splat(@splat(0));
    var weights: [MAX_ITEMS][MAX_ATOMS]i64 = @splat(@splat(0));
    var position: usize = 2;
    for (0..n) |item| {
        if (position + 2 > length) return -1;
        const item_reward = input[position]; position += 1;
        const atom_count_raw = input[position]; position += 1;
        if (item_reward < 0 or item_reward > 20 or atom_count_raw < 1 or atom_count_raw > @as(i64, MAX_ATOMS)) return -1;
        reward[item] = item_reward;
        atom_count[item] = @intCast(atom_count_raw);
        for (0..atom_count[item]) |atom| {
            if (position + 2 > length) return -1;
            const size = input[position]; position += 1;
            const weight = input[position]; position += 1;
            if (size < 0 or size > bound + 1 or weight < 1 or weight > 3) return -1;
            sizes[item][atom] = size;
            weights[item][atom] = weight;
            denominator[item] += weight;
            if (size <= bound) fit[item] += weight;
            mean[item] += @min(size, bound) * weight;
        }
        if (denominator[item] > 9 or mean[item] == 0) return -1;
    }
    if (position != length) return -1;

    var order: [MAX_ITEMS]usize = @splat(0);
    for (0..n) |i| {
        var j = i;
        while (j > 0 and density_before(i, order[j - 1], &reward, &fit, &mean)) : (j -= 1) {
            order[j] = order[j - 1];
        }
        order[j] = i;
    }
    var best_single: usize = 0;
    for (1..n) |i| {
        const left = reward[i] * fit[i] * denominator[best_single];
        const right = reward[best_single] * fit[best_single] * denominator[i];
        if (left > right) best_single = i;
    }

    var joint_denominator: i64 = 1;
    var scenario_count: usize = 1;
    for (0..n) |i| {
        joint_denominator *= denominator[i];
        scenario_count *= atom_count[i];
    }
    var singleton_score: i64 = 0;
    var order_score: i64 = 0;
    for (0..scenario_count) |scenario| {
        var digits = scenario;
        var scenario_weight: i64 = 1;
        var selected_size: [MAX_ITEMS]i64 = @splat(0);
        for (0..n) |item| {
            const atom = digits % atom_count[item];
            digits /= atom_count[item];
            selected_size[item] = sizes[item][atom];
            scenario_weight *= weights[item][atom];
        }
        if (selected_size[best_single] <= bound) singleton_score += scenario_weight * reward[best_single];
        var used: i64 = 0;
        var earned: i64 = 0;
        for (0..n) |rank| {
            const item = order[rank];
            if (used + selected_size[item] > bound) break;
            used += selected_size[item];
            earned += reward[item];
        }
        order_score += scenario_weight * earned;
    }

    const use_order = order_score > singleton_score;
    const output_count: usize = if (use_order) n else 1;
    var staged: [MAX_OUTPUT_WORDS]i64 = @splat(0);
    staged[0] = if (use_order) 1 else 0;
    staged[1] = @intCast(output_count);
    for (0..output_count) |i| staged[2 + i] = @intCast(if (use_order) order[i] else best_single);
    staged[2 + output_count] = if (use_order) order_score else singleton_score;
    staged[3 + output_count] = joint_denominator;
    const words = output_count + 4;
    const output_bytes = words * 8;
    if (output_opt == null or capacity < output_bytes) return -2;
    const output = output_opt.?;
    for (0..words) |word| store_i64_le(output, word * 8, staged[word]);
    return @intCast(output_bytes);
}
