const MAX_VERTEX_COUNT: usize = 63;
const MAX_EDGE_COUNT: usize = 2047;
const MAX_INPUT_LENGTH: usize = 3 + 2 * MAX_EDGE_COUNT;

fn countBits(value: u64) usize {
    var remaining = value;
    var count: usize = 0;
    while (remaining != 0) {
        remaining &= remaining - 1;
        count += 1;
    }
    return count;
}

export fn dominator_tree(input: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length < 3 or length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 1 or input[0] > @as(i64, @intCast(MAX_VERTEX_COUNT)) or
        input[1] < 0 or input[1] >= input[0] or input[2] < 0 or
        input[2] > @as(i64, @intCast(MAX_EDGE_COUNT))) return -1;
    const vertex_count: usize = @intCast(input[0]);
    const root: usize = @intCast(input[1]);
    const edge_count: usize = @intCast(input[2]);
    if (length != 3 + 2 * edge_count) return -1;

    var outgoing = [_]u64{0} ** MAX_VERTEX_COUNT;
    for (0..edge_count) |edge| {
        const from_value = input[3 + 2 * edge];
        const to_value = input[4 + 2 * edge];
        if (from_value < 0 or to_value < 0 or
            from_value >= @as(i64, @intCast(vertex_count)) or
            to_value >= @as(i64, @intCast(vertex_count))) return -1;
        const from: usize = @intCast(from_value);
        const to: usize = @intCast(to_value);
        outgoing[from] |= @as(u64, 1) << @intCast(to);
    }

    var reachable: u64 = @as(u64, 1) << @intCast(root);
    var frontier = reachable;
    while (frontier != 0) {
        var discovered: u64 = 0;
        for (0..vertex_count) |vertex| {
            if (frontier & (@as(u64, 1) << @intCast(vertex)) != 0) discovered |= outgoing[vertex];
        }
        discovered &= ~reachable;
        reachable |= discovered;
        frontier = discovered;
    }

    var dominators = [_]u64{0} ** MAX_VERTEX_COUNT;
    dominators[root] = @as(u64, 1) << @intCast(root);
    for (0..vertex_count) |vertex| {
        if (reachable & (@as(u64, 1) << @intCast(vertex)) != 0 and vertex != root)
            dominators[vertex] = reachable;
    }

    var changed = true;
    while (changed) {
        changed = false;
        for (0..vertex_count) |vertex| {
            const vertex_bit = @as(u64, 1) << @intCast(vertex);
            if (reachable & vertex_bit == 0 or vertex == root) continue;
            var common = reachable;
            for (0..vertex_count) |predecessor| {
                if (reachable & (@as(u64, 1) << @intCast(predecessor)) != 0 and
                    outgoing[predecessor] & vertex_bit != 0)
                    common &= dominators[predecessor];
            }
            const updated = common | vertex_bit;
            if (updated != dominators[vertex]) {
                dominators[vertex] = updated;
                changed = true;
            }
        }
    }

    if (output == null or output_capacity < vertex_count) return -2;
    for (0..vertex_count) |vertex| {
        const vertex_bit = @as(u64, 1) << @intCast(vertex);
        if (reachable & vertex_bit == 0) {
            output[vertex] = 255;
        } else if (vertex == root) {
            output[vertex] = @intCast(root);
        } else {
            const strict = dominators[vertex] & ~vertex_bit;
            var best = root;
            var best_depth: usize = 0;
            for (0..vertex_count) |candidate| {
                if (strict & (@as(u64, 1) << @intCast(candidate)) == 0) continue;
                const depth = countBits(dominators[candidate]);
                if (depth > best_depth) {
                    best = candidate;
                    best_depth = depth;
                }
            }
            output[vertex] = @intCast(best);
        }
    }
    return @intCast(vertex_count);
}
