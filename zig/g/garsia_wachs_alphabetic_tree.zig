const MAX_N: usize = 64;
const MAX_NODE: usize = 2 * MAX_N - 1;
const MAX_INPUT: usize = MAX_N + 2;
const MAX_WEIGHT: i64 = 1_000_000;
const GW_INFINITY: i64 = 1 << 62;

fn putI64(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn garsia_wachs_alphabetic_tree(input: [*c]const i64, input_length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or input_length < 2 or input_length > MAX_INPUT) return -1;
    const n_value = input[0];
    if (n_value < 1 or n_value > MAX_N) return -1;
    const n: usize = @intCast(n_value);
    if (input_length != n + 1) return -1;

    var node_weight: [MAX_NODE]i64 = [_]i64{0} ** MAX_NODE;
    var left: [MAX_NODE]i32 = [_]i32{-1} ** MAX_NODE;
    var right: [MAX_NODE]i32 = [_]i32{-1} ** MAX_NODE;
    var active: [MAX_N]usize = undefined;
    for (0..n) |i| {
        if (input[i + 1] < 0 or input[i + 1] > MAX_WEIGHT) return -1;
        node_weight[i] = input[i + 1];
        active[i] = i;
    }
    var active_count = n;
    var next_node = n;
    while (active_count > 1) {
        var pair: usize = 0;
        while (pair + 1 < active_count) {
            const following = if (pair + 2 < active_count) node_weight[active[pair + 2]] else GW_INFINITY;
            if (node_weight[active[pair]] <= following) break;
            pair += 1;
        }
        const first = active[pair];
        const second = active[pair + 1];
        const combined = node_weight[first] + node_weight[second];
        node_weight[next_node] = combined;
        left[next_node] = @intCast(first);
        right[next_node] = @intCast(second);
        var earlier = pair;
        while (earlier > 0 and node_weight[active[earlier - 1]] < combined) earlier -= 1;
        const insert_at = earlier;
        var i = pair;
        while (i + 2 < active_count) : (i += 1) active[i] = active[i + 2];
        active_count -= 2;
        i = active_count;
        while (i > insert_at) : (i -= 1) active[i] = active[i - 1];
        active[insert_at] = next_node;
        active_count += 1;
        next_node += 1;
    }

    var depths: [MAX_N]usize = [_]usize{0} ** MAX_N;
    var stack_node: [2 * MAX_N]usize = undefined;
    var stack_depth: [2 * MAX_N]usize = undefined;
    var top: usize = 1;
    stack_node[0] = active[0];
    while (top > 0) {
        top -= 1;
        const node = stack_node[top];
        const depth = stack_depth[top];
        if (node < n) {
            depths[node] = depth;
        } else {
            stack_node[top] = @intCast(right[node]);
            stack_depth[top] = depth + 1;
            top += 1;
            stack_node[top] = @intCast(left[node]);
            stack_depth[top] = depth + 1;
            top += 1;
        }
    }

    var ordered_left: [MAX_NODE]i32 = [_]i32{-1} ** MAX_NODE;
    var ordered_right: [MAX_NODE]i32 = [_]i32{-1} ** MAX_NODE;
    var code_node: [2 * MAX_N]usize = undefined;
    var code_depth: [2 * MAX_N]usize = undefined;
    var code_top: usize = 0;
    var next_ordered = n;
    for (0..n) |leaf| {
        code_node[code_top] = leaf;
        code_depth[code_top] = depths[leaf];
        code_top += 1;
        while (code_top >= 2 and code_depth[code_top - 1] == code_depth[code_top - 2]) {
            const level = code_depth[code_top - 1];
            if (level == 0 or next_ordered >= 2 * n - 1) return -1;
            ordered_left[next_ordered] = @intCast(code_node[code_top - 2]);
            ordered_right[next_ordered] = @intCast(code_node[code_top - 1]);
            code_top -= 2;
            code_node[code_top] = next_ordered;
            code_depth[code_top] = level - 1;
            code_top += 1;
            next_ordered += 1;
        }
    }
    if (code_top != 1 or code_depth[0] != 0 or next_ordered != 2 * n - 1) return -1;

    var cost: i64 = 0;
    for (0..n) |i| cost += input[i + 1] * @as(i64, @intCast(depths[i]));
    const output_bytes = 8 * (n + 1);
    if (output == null or output_capacity < output_bytes) return -2;
    putI64(output, 0, cost);
    for (0..n) |i| putI64(output, 8 * (i + 1), @intCast(depths[i]));
    return @intCast(output_bytes);
}
