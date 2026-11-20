pub export fn k_ary_huffman_weighted_path_cost(input: ?[*]const i64, length: usize) callconv(.c) i64 {
    const values = input orelse return -1;
    if (length < 3 or length > 13) return -1;
    const arity_value = values[0];
    const count_value = values[1];
    if ((arity_value != 3 and arity_value != 4) or count_value < 1 or count_value > 10) return -1;
    const arity: usize = @intCast(arity_value);
    const count: usize = @intCast(count_value);
    if (length != count + 2 or (count > 1 and (count - 1) % (arity - 1) != 0)) return -1;

    var weights = [_]i64{0} ** 16;
    var active = [_]bool{false} ** 16;
    for (0..count) |index| {
        const weight = values[index + 2];
        if (weight < 0 or weight > 1000) return -1;
        weights[index] = weight;
        active[index] = true;
    }

    var node_count = count;
    var active_count = count;
    var cost: i64 = 0;
    while (active_count > 1) {
        var combined: i64 = 0;
        for (0..arity) |_| {
            var best: ?usize = null;
            for (0..node_count) |index| {
                if (!active[index]) continue;
                if (best == null) best = index
                else if (weights[index] < weights[best.?]
                    or (weights[index] == weights[best.?] and index < best.?)) best = index;
            }
            const chosen = best orelse return -1;
            combined += weights[chosen];
            active[chosen] = false;
            active_count -= 1;
        }
        cost += combined;
        weights[node_count] = combined;
        active[node_count] = true;
        node_count += 1;
        active_count += 1;
    }
    return cost;
}
