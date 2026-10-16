const MAX_N: usize = 64;
const MAX_Q: usize = 128;

fn putI64(output: [*]u8, slot: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[slot * 8 + byte] = @truncate(bits >> @intCast(byte * 8));
}

fn rangeMax(tree: *const [MAX_N * 2]i64, n: usize, left: usize, right: usize) i64 {
    var l = left + n;
    var r = right + n + 1;
    var maximum: i64 = -2147483648;
    while (l < r) {
        if (l & 1 != 0) { maximum = @max(maximum, tree[l]); l += 1; }
        if (r & 1 != 0) { r -= 1; maximum = @max(maximum, tree[r]); }
        l >>= 1;
        r >>= 1;
    }
    return maximum;
}

fn pointSet(tree: *[MAX_N * 2]i64, n: usize, position: usize, value: i64) void {
    var p = position + n;
    tree[p] = value;
    while (p > 1) {
        p >>= 1;
        tree[p] = @max(tree[p * 2], tree[p * 2 + 1]);
    }
}

fn pathMax(tree: *const [MAX_N * 2]i64, n: usize,
    parent: *const [MAX_N]usize, depth: *const [MAX_N]usize,
    head: *const [MAX_N]usize, position: *const [MAX_N]usize,
    a_value: usize, b_value: usize) i64 {
    var a = a_value;
    var b = b_value;
    var maximum: i64 = -2147483648;
    while (head[a] != head[b]) {
        if (depth[head[a]] < depth[head[b]]) { const t = a; a = b; b = t; }
        maximum = @max(maximum, rangeMax(tree, n, position[head[a]], position[a]));
        a = parent[head[a]];
    }
    if (depth[a] > depth[b]) { const t = a; a = b; b = t; }
    return @max(maximum, rangeMax(tree, n, position[a], position[b]));
}

export fn heavy_light_path_max(input: [*c]const i64, length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 2) return -1;
    const values = input[0..length];
    const nv = values[0];
    const qv = values[1];
    if (nv < 1 or nv > MAX_N or qv < 0 or qv > MAX_Q) return -1;
    const n: usize = @intCast(nv);
    const q: usize = @intCast(qv);
    if (length != 3 * n + 3 * q) return -1;

    var node_values: [MAX_N]i64 = @splat(0);
    var cursor: usize = 2;
    for (0..n) |v| {
        node_values[v] = values[cursor];
        if (node_values[v] < -2147483648 or node_values[v] > 2147483647) return -1;
        cursor += 1;
    }
    var adjacency: [MAX_N][MAX_N]usize = @splat(@splat(0));
    var degree: [MAX_N]usize = @splat(0);
    for (0..(n - 1)) |_| {
        const uv = values[cursor];
        const vv = values[cursor + 1];
        cursor += 2;
        if (uv < 0 or uv >= nv or vv < 0 or vv >= nv or uv == vv) return -1;
        const u: usize = @intCast(uv);
        const v: usize = @intCast(vv);
        for (0..degree[u]) |i| {
            if (adjacency[u][i] == v) return -1;
        }
        adjacency[u][degree[u]] = v; degree[u] += 1;
        adjacency[v][degree[v]] = u; degree[v] += 1;
    }

    var parent: [MAX_N]usize = @splat(MAX_N);
    var depth: [MAX_N]usize = @splat(0);
    var order: [MAX_N]usize = @splat(0);
    var stack: [MAX_N]usize = @splat(0);
    parent[0] = 0;
    var top: usize = 1;
    var order_count: usize = 0;
    stack[0] = 0;
    while (top > 0) {
        top -= 1;
        const u = stack[top];
        order[order_count] = u; order_count += 1;
        for (0..degree[u]) |i| {
            const v = adjacency[u][i];
            if (v == parent[u]) continue;
            if (parent[v] != MAX_N) return -1;
            parent[v] = u; depth[v] = depth[u] + 1;
            stack[top] = v; top += 1;
        }
    }
    if (order_count != n) return -1;

    var subtree: [MAX_N]usize = @splat(1);
    var heavy: [MAX_N]usize = @splat(MAX_N);
    var index = n;
    while (index > 1) {
        index -= 1;
        const v = order[index];
        const p = parent[v];
        subtree[p] += subtree[v];
        if (heavy[p] == MAX_N or subtree[v] > subtree[heavy[p]]) heavy[p] = v;
    }
    var head: [MAX_N]usize = @splat(0);
    var position: [MAX_N]usize = @splat(0);
    var todo_vertex: [MAX_N]usize = @splat(0);
    var todo_head: [MAX_N]usize = @splat(0);
    var base: [MAX_N]i64 = @splat(0);
    top = 1;
    var timer: usize = 0;
    todo_vertex[0] = 0; todo_head[0] = 0;
    while (top > 0) {
        top -= 1;
        var u = todo_vertex[top];
        const chain = todo_head[top];
        while (u != MAX_N) {
            head[u] = chain;
            position[u] = timer;
            base[timer] = node_values[u];
            timer += 1;
            for (0..degree[u]) |i| {
                const v = adjacency[u][i];
                if (parent[v] == u and v != heavy[u]) {
                    todo_vertex[top] = v; todo_head[top] = v; top += 1;
                }
            }
            u = heavy[u];
        }
    }
    var segment: [MAX_N * 2]i64 = @splat(0);
    for (0..n) |i| segment[n + i] = base[i];
    index = n;
    while (index > 1) { index -= 1; segment[index] = @max(segment[index * 2], segment[index * 2 + 1]); }

    var results: [MAX_Q]i64 = @splat(0);
    var result_count: usize = 0;
    const operations = cursor;
    for (0..q) |i| {
        const op = values[operations + 3 * i];
        const av = values[operations + 3 * i + 1];
        const bv = values[operations + 3 * i + 2];
        if (op == 0) {
            if (av < 0 or av >= nv or bv < -2147483648 or bv > 2147483647) return -1;
            const v: usize = @intCast(av);
            node_values[v] = bv;
            pointSet(&segment, n, position[v], bv);
        } else if (op == 1) {
            if (av < 0 or av >= nv or bv < 0 or bv >= nv) return -1;
            results[result_count] = pathMax(&segment, n, &parent, &depth, &head, &position, @intCast(av), @intCast(bv));
            result_count += 1;
        } else return -1;
    }
    const output_bytes = result_count * 8;
    if (output_bytes > 0 and (output == null or capacity < output_bytes)) return -2;
    if (output_bytes > 0) {
        for (0..result_count) |i| putI64(output, i, results[i]);
    }
    return @intCast(output_bytes);
}
