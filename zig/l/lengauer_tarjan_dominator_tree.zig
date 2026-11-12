const MAX_V: usize = 63;
const MAX_E: usize = 2047;
const MAX_INPUT: usize = 4097;

fn evaluate(vertex: usize, ancestor: *[MAX_V + 1]i32,
    label: *[MAX_V + 1]i32, semi: *const [MAX_V + 1]i32,
    path: *[MAX_V + 1]i32) usize {
    if (ancestor[vertex] == 0) return vertex;
    var used: usize = 0;
    var current = vertex;
    while (ancestor[@intCast(ancestor[current])] != 0) {
        path[used] = @intCast(current);
        used += 1;
        current = @intCast(ancestor[current]);
    }
    while (used > 0) {
        used -= 1;
        current = @intCast(path[used]);
        const parent: usize = @intCast(ancestor[current]);
        if (semi[@intCast(label[parent])] < semi[@intCast(label[current])]) {
            label[current] = label[parent];
        }
        ancestor[current] = ancestor[parent];
    }
    return @intCast(label[vertex]);
}

export fn lengauer_tarjan_dominator_tree(input: [*c]const i64, length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 3 or length > MAX_INPUT) return -1;
    const nv = input[0];
    const root_value = input[1];
    const me = input[2];
    if (nv < 1 or nv > @as(i64, @intCast(MAX_V)) or root_value < 0 or root_value >= nv or
        me < 0 or me > @as(i64, @intCast(MAX_E))) return -1;
    const n: usize = @intCast(nv);
    const root: usize = @intCast(root_value);
    const m: usize = @intCast(me);
    if (length != 3 + 2 * m) return -1;

    var outmask: [MAX_V]u64 = @splat(0);
    var out_head: [MAX_V]i32 = @splat(-1);
    var edge_source: [MAX_E]i32 = @splat(0);
    var edge_target: [MAX_E]i32 = @splat(0);
    var out_next: [MAX_E]i32 = @splat(-1);
    var pred_head: [MAX_V + 1]i32 = @splat(-1);
    var pred_next: [MAX_E]i32 = @splat(-1);
    var dfs_number: [MAX_V]i32 = @splat(0);
    var vertex_at: [MAX_V + 1]i32 = @splat(0);
    var parent: [MAX_V + 1]i32 = @splat(0);
    var semi: [MAX_V + 1]i32 = @splat(0);
    var ancestor: [MAX_V + 1]i32 = @splat(0);
    var label: [MAX_V + 1]i32 = @splat(0);
    var immediate: [MAX_V + 1]i32 = @splat(0);
    var bucket_head: [MAX_V + 1]i32 = @splat(-1);
    var bucket_next: [MAX_V + 1]i32 = @splat(0);
    var node_stack: [MAX_V]usize = @splat(0);
    var edge_stack: [MAX_V]i32 = @splat(-1);
    var eval_path: [MAX_V + 1]i32 = @splat(0);
    var staged: [MAX_V]u8 = @splat(0);
    var edge_count: usize = 0;

    for (0..m) |index| {
        const sv = input[3 + 2 * index];
        const tv = input[4 + 2 * index];
        if (sv < 0 or sv >= nv or tv < 0 or tv >= nv) return -1;
        const source: usize = @intCast(sv);
        const target: usize = @intCast(tv);
        const bit = @as(u64, 1) << @intCast(target);
        if (outmask[source] & bit == 0) {
            outmask[source] |= bit;
            edge_source[edge_count] = @intCast(source);
            edge_target[edge_count] = @intCast(target);
            out_next[edge_count] = out_head[source];
            out_head[source] = @intCast(edge_count);
            edge_count += 1;
        }
    }

    var dfs_count: usize = 1;
    var top: usize = 1;
    dfs_number[root] = 1;
    vertex_at[1] = @intCast(root);
    node_stack[0] = root;
    edge_stack[0] = out_head[root];
    while (top > 0) {
        const frame = top - 1;
        const current = node_stack[frame];
        const edge = edge_stack[frame];
        if (edge == -1) { top -= 1; continue; }
        edge_stack[frame] = out_next[@intCast(edge)];
        const target: usize = @intCast(edge_target[@intCast(edge)]);
        if (dfs_number[target] == 0) {
            dfs_count += 1;
            dfs_number[target] = @intCast(dfs_count);
            vertex_at[dfs_count] = @intCast(target);
            parent[dfs_count] = dfs_number[current];
            node_stack[top] = target;
            edge_stack[top] = out_head[target];
            top += 1;
        }
    }

    for (0..edge_count) |edge| {
        const source_number = dfs_number[@intCast(edge_source[edge])];
        const target_number = dfs_number[@intCast(edge_target[edge])];
        if (source_number != 0 and target_number != 0) {
            pred_next[edge] = pred_head[@intCast(target_number)];
            pred_head[@intCast(target_number)] = @intCast(edge);
        }
    }
    for (1..dfs_count + 1) |vertex| {
        semi[vertex] = @intCast(vertex);
        label[vertex] = @intCast(vertex);
    }

    var w = dfs_count;
    while (w >= 2) : (w -= 1) {
        var edge = pred_head[w];
        while (edge != -1) {
            const index: usize = @intCast(edge);
            const predecessor: usize = @intCast(dfs_number[@intCast(edge_source[index])]);
            const representative = evaluate(predecessor, &ancestor, &label, &semi, &eval_path);
            if (semi[representative] < semi[w]) semi[w] = semi[representative];
            edge = pred_next[index];
        }
        bucket_next[w] = bucket_head[@intCast(semi[w])];
        bucket_head[@intCast(semi[w])] = @intCast(w);
        ancestor[w] = parent[w];
        const owner: usize = @intCast(parent[w]);
        var member = bucket_head[owner];
        bucket_head[owner] = -1;
        while (member != -1) {
            const vertex: usize = @intCast(member);
            const next = bucket_next[vertex];
            const representative = evaluate(vertex, &ancestor, &label, &semi, &eval_path);
            immediate[vertex] = if (semi[representative] < semi[vertex])
                @intCast(representative)
            else
                @intCast(owner);
            member = next;
        }
    }
    for (2..dfs_count + 1) |vertex| {
        if (immediate[vertex] != semi[vertex]) immediate[vertex] = immediate[@intCast(immediate[vertex])];
    }
    immediate[1] = 1;

    for (0..n) |vertex| {
        const number = dfs_number[vertex];
        staged[vertex] = if (number == 0) 255 else
            @intCast(vertex_at[@intCast(immediate[@intCast(number)])]);
    }
    if (output == null or capacity < n) return -2;
    for (0..n) |vertex| output[vertex] = staged[vertex];
    return @intCast(n);
}
