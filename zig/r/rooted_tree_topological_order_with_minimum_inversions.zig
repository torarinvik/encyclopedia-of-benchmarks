const MAX_N: usize = 12;
const MAX_INPUT_VALUES: usize = 3 * MAX_N + 1;
const MAX_OUTPUT_WORDS: usize = MAX_N + 1;
const MAX_WEIGHT: i64 = 1_000_000;

fn findRoot(parent: *[MAX_N]usize, vertex: usize) usize {
    var root = vertex;
    while (parent[root] != root) root = parent[root];
    var current = vertex;
    while (parent[current] != current) {
        const next = parent[current];
        parent[current] = root;
        current = next;
    }
    return root;
}

fn compareRatio(left_c: i64, left_d: i64, right_c: i64, right_d: i64) i32 {
    const left_zero = left_c == 0 and left_d == 0;
    const right_zero = right_c == 0 and right_d == 0;
    if (left_zero != right_zero) return if (left_zero) -1 else 1;
    const lhs = left_c * right_d;
    const rhs = left_d * right_c;
    return @as(i32, @intFromBool(lhs > rhs)) - @as(i32, @intFromBool(lhs < rhs));
}

fn storeI64Le(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn rooted_tree_topological_order_with_minimum_inversions(
    input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize,
) i64 {
    if (input == null or length < 3 or length > MAX_INPUT_VALUES) return -1;
    const n_value = input[0];
    if (n_value < 1 or n_value > @as(i64, @intCast(MAX_N)) or
        length != 3 * @as(usize, @intCast(n_value))) return -1;
    const n: usize = @intCast(n_value);

    var tree_parent: [MAX_N]usize = @splat(0);
    for (1..n) |vertex| {
        const parent_value = input[vertex];
        if (parent_value < 0 or parent_value >= @as(i64, @intCast(vertex))) return -1;
        tree_parent[vertex] = @intCast(parent_value);
    }

    var original_c: [MAX_N]i64 = @splat(0);
    var original_d: [MAX_N]i64 = @splat(0);
    var aggregate_c: [MAX_N]i64 = @splat(0);
    var aggregate_d: [MAX_N]i64 = @splat(0);
    var sum_c: i64 = 0;
    var sum_d: i64 = 0;
    for (0..n) |vertex| {
        const c = input[n + vertex];
        const d = input[2 * n + vertex];
        if (c < 0 or c > MAX_WEIGHT or d < 0 or d > MAX_WEIGHT) return -1;
        sum_c += c;
        sum_d += d;
        if (sum_c > MAX_WEIGHT or sum_d > MAX_WEIGHT) return -1;
        original_c[vertex] = c;
        original_d[vertex] = d;
        aggregate_c[vertex] = c;
        aggregate_d[vertex] = d;
    }

    var dsu_parent: [MAX_N]usize = @splat(0);
    var component_label: [MAX_N]usize = @splat(0);
    var active: [MAX_N]bool = @splat(false);
    var link: [MAX_N]usize = @splat(0);
    for (0..n) |vertex| {
        dsu_parent[vertex] = vertex;
        component_label[vertex] = vertex;
        active[vertex] = vertex != 0;
        link[vertex] = vertex;
    }

    for (0..n - 1) |_| {
        var selected: ?usize = null;
        for (1..n) |candidate| {
            if (!active[candidate]) continue;
            if (selected == null) { selected = candidate; continue; }
            const current = selected.?;
            const comparison = compareRatio(aggregate_c[candidate], aggregate_d[candidate],
                                            aggregate_c[current], aggregate_d[current]);
            if (comparison > 0 or (comparison == 0 and candidate > current)) selected = candidate;
        }
        const child = selected orelse return -1;
        const parent_component = findRoot(&dsu_parent, tree_parent[child]);
        const target = component_label[parent_component];
        const child_component = findRoot(&dsu_parent, child);
        if (child_component == parent_component) return -1;
        aggregate_c[target] += aggregate_c[child];
        aggregate_d[target] += aggregate_d[child];
        dsu_parent[child_component] = parent_component;
        component_label[parent_component] = target;
        active[child] = false;
        if (target != 0) active[target] = true;
        const next = link[child];
        link[child] = link[target];
        link[target] = next;
    }

    var traversal: [MAX_N]usize = @splat(0);
    var count: usize = 0;
    var vertex = link[0];
    while (count < n) {
        traversal[count] = vertex;
        count += 1;
        if (vertex == 0) break;
        vertex = link[vertex];
    }
    if (count != n or traversal[count - 1] != 0) return -1;

    var words: [MAX_OUTPUT_WORDS]i64 = @splat(0);
    var prefix_d: i64 = 0;
    var objective: i64 = 0;
    for (0..n) |index| {
        const ordered_vertex = traversal[n - 1 - index];
        words[index + 1] = @intCast(ordered_vertex);
        objective += prefix_d * original_c[ordered_vertex];
        prefix_d += original_d[ordered_vertex];
    }
    words[0] = objective;
    const output_bytes = 8 * (n + 1);
    if (output == null or capacity < output_bytes) return -2;
    for (0..n + 1) |word| storeI64Le(output, 8 * word, words[word]);
    return @intCast(output_bytes);
}
