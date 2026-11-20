const MAX_S: i64 = 4_222_124_650_659_840;
const RESULT_FACTOR: i64 = MAX_S + 1;

export fn tunstall_codebook_construction(input: ?[*]const i64, length: usize) i64 {
    const values = input orelse return -1;
    if (length < 4 or length > 7) return -1;
    if (values[0] < 2 or values[0] > 4 or values[1] < 2 or values[1] > 4) return -1;
    const k: usize = @intCast(values[0]);
    const bits: usize = @intCast(values[1]);
    if (length != k + 2) return -1;
    var weights = [_]i64{0} ** 4;
    var total: i64 = 0;
    for (0..k) |symbol| {
        const weight = values[2 + symbol];
        if (weight <= 0 or weight > 8) return -1;
        weights[symbol] = weight;
        total += weight;
    }
    if (total > 8) return -1;

    var powers = [_]i64{0} ** 17;
    powers[0] = 1;
    for (1..17) |exponent| powers[exponent] = powers[exponent - 1] * total;
    const cap: usize = @as(usize, 1) << @intCast(bits);
    var target = cap;
    while ((target - 1) % (k - 1) != 0) : (target -= 1) {}

    var products = [_]i64{0} ** 31;
    var depths = [_]usize{0} ** 31;
    var phrase_keys = [_]u64{0} ** 31;
    var leaves = [_]usize{0} ** 16;
    var node_count: usize = 1;
    var leaf_count: usize = 0;
    for (0..k) |symbol| {
        const node = node_count;
        node_count += 1;
        products[node] = weights[symbol];
        depths[node] = 1;
        phrase_keys[node] = @as(u64, @intCast(symbol + 1)) << 56;
        leaves[leaf_count] = node;
        leaf_count += 1;
    }

    var scaled_expectation = powers[16];
    while (leaf_count < target) {
        var best_position: usize = 0;
        var best_node = leaves[0];
        var best_probability = products[best_node] * powers[15 - depths[best_node]];
        for (1..leaf_count) |position| {
            const candidate = leaves[position];
            const probability = products[candidate] * powers[15 - depths[candidate]];
            if (probability > best_probability or
                (probability == best_probability and phrase_keys[candidate] < phrase_keys[best_node]))
            {
                best_position = position;
                best_node = candidate;
                best_probability = probability;
            }
        }

        scaled_expectation += products[best_node] * powers[16 - depths[best_node]];
        leaf_count -= 1;
        leaves[best_position] = leaves[leaf_count];
        for (0..k) |symbol| {
            const child = node_count;
            node_count += 1;
            products[child] = products[best_node] * weights[symbol];
            depths[child] = depths[best_node] + 1;
            const shift = 4 * (14 - depths[best_node]);
            phrase_keys[child] = phrase_keys[best_node] | (@as(u64, @intCast(symbol + 1)) << @intCast(shift));
            leaves[leaf_count] = child;
            leaf_count += 1;
        }
    }
    if (scaled_expectation > MAX_S) return -1;
    return @as(i64, @intCast(target)) * RESULT_FACTOR + scaled_expectation;
}
