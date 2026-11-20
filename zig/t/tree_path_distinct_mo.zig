const max_n: usize = 32;
const max_q: usize = 32;
const max_input: usize = 3 * max_n + 2 * max_q;
const max_cells: usize = max_n * max_n;

const Query = struct {
    left: usize,
    right: usize,
    id: usize,
    block: usize,
    right_key: usize,
};

fn findRoot(parent: *[max_n]usize, item: usize) usize {
    var node = item;
    while (parent[node] != node) {
        parent[node] = parent[parent[node]];
        node = parent[node];
    }
    return node;
}

fn less(a: Query, b: Query) bool {
    if (a.block != b.block) return a.block < b.block;
    if (a.right_key != b.right_key) return a.right_key < b.right_key;
    return a.id < b.id;
}

fn siftDown(values: *[max_q]Query, root_start: usize, end: usize) void {
    var root = root_start;
    while (root * 2 + 1 < end) {
        const child = root * 2 + 1;
        var largest = root;
        if (less(values[largest], values[child])) largest = child;
        if (child + 1 < end and less(values[largest], values[child + 1])) largest = child + 1;
        if (largest == root) return;
        const temporary = values[root];
        values[root] = values[largest];
        values[largest] = temporary;
        root = largest;
    }
}

fn sortQueries(values: *[max_q]Query, count: usize) void {
    var start = count / 2;
    while (start > 0) {
        start -= 1;
        siftDown(values, start, count);
    }
    var end = count;
    while (end > 1) {
        end -= 1;
        const temporary = values[0];
        values[0] = values[end];
        values[end] = temporary;
        siftDown(values, 0, end);
    }
}

fn lca(a_raw: usize, b_raw: usize, parent: *const [max_n]usize,
    depth: *const [max_n]usize) usize {
    var a = a_raw;
    var b = b_raw;
    while (depth[a] > depth[b]) a = parent[a];
    while (depth[b] > depth[a]) b = parent[b];
    while (a != b) {
        a = parent[a];
        b = parent[b];
    }
    return a;
}

fn toggle(vertex: usize, color_id: *const [max_n]usize, counts: *[max_n]usize,
    active: *[max_n]bool, distinct: *usize) void {
    const color = color_id[vertex];
    if (active[vertex]) {
        active[vertex] = false;
        counts[color] -= 1;
        if (counts[color] == 0) distinct.* -= 1;
    } else {
        active[vertex] = true;
        if (counts[color] == 0) distinct.* += 1;
        counts[color] += 1;
    }
}

fn storeLe(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn tree_path_distinct_mo(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 3 or length > max_input + 1) return -1;
    const input = input_opt.?;
    const n_value = input[0];
    const q_value = input[1];
    if (n_value < 1 or n_value > @as(i64, @intCast(max_n)) or
        q_value < 0 or q_value > @as(i64, @intCast(max_q))) return -1;
    const n: usize = @intCast(n_value);
    const q: usize = @intCast(q_value);
    if (length != 3 * n + 2 * q) return -1;

    var colors: [max_n]i64 = @splat(0);
    for (0..n) |vertex| colors[vertex] = input[2 + vertex];
    var adjacent: [max_cells]bool = @splat(false);
    var dsu_parent: [max_n]usize = undefined;
    var dsu_size: [max_n]usize = undefined;
    for (0..n) |vertex| {
        dsu_parent[vertex] = vertex;
        dsu_size[vertex] = 1;
    }
    var offset = 2 + n;
    for (0..(n - 1)) |_| {
        const u_value = input[offset];
        const v_value = input[offset + 1];
        offset += 2;
        if (u_value < 0 or u_value >= n_value or v_value < 0 or v_value >= n_value or u_value == v_value)
            return -1;
        const u: usize = @intCast(u_value);
        const v: usize = @intCast(v_value);
        var root_u = findRoot(&dsu_parent, u);
        var root_v = findRoot(&dsu_parent, v);
        if (root_u == root_v) return -1;
        if (dsu_size[root_u] < dsu_size[root_v]) {
            const temporary = root_u;
            root_u = root_v;
            root_v = temporary;
        }
        dsu_parent[root_v] = root_u;
        dsu_size[root_u] += dsu_size[root_v];
        adjacent[u * max_n + v] = true;
        adjacent[v * max_n + u] = true;
    }

    var query_u: [max_q]usize = @splat(0);
    var query_v: [max_q]usize = @splat(0);
    for (0..q) |id| {
        const u_value = input[offset];
        const v_value = input[offset + 1];
        offset += 2;
        if (u_value < 0 or u_value >= n_value or v_value < 0 or v_value >= n_value) return -1;
        query_u[id] = @intCast(u_value);
        query_v[id] = @intCast(v_value);
    }

    var color_id: [max_n]usize = @splat(0);
    var first_color: [max_n]usize = undefined;
    var color_count: usize = 0;
    for (0..n) |vertex| {
        var rank: usize = 0;
        while (rank < color_count and colors[first_color[rank]] != colors[vertex]) : (rank += 1) {}
        if (rank == color_count) {
            first_color[color_count] = vertex;
            color_count += 1;
        }
        color_id[vertex] = rank;
    }

    var parent: [max_n]usize = @splat(n);
    var depth: [max_n]usize = @splat(0);
    var entry: [max_n]usize = @splat(0);
    var leave: [max_n]usize = @splat(0);
    var euler: [2 * max_n]usize = @splat(0);
    var event_node: [2 * max_n]usize = @splat(0);
    var event_parent: [2 * max_n]usize = @splat(0);
    var event_exit: [2 * max_n]bool = @splat(false);
    var top: usize = 1;
    var clock: usize = 0;
    event_node[0] = 0;
    event_parent[0] = n;
    while (top > 0) {
        top -= 1;
        const u = event_node[top];
        const previous = event_parent[top];
        if (event_exit[top]) {
            leave[u] = clock;
            euler[clock] = u;
            clock += 1;
        } else {
            parent[u] = previous;
            entry[u] = clock;
            euler[clock] = u;
            clock += 1;
            event_node[top] = u;
            event_parent[top] = previous;
            event_exit[top] = true;
            top += 1;
            for (step in 0..n) {
                const v = n - 1 - step;
                if (adjacent[u * max_n + v] and v != previous) {
                    depth[v] = depth[u] + 1;
                    event_node[top] = v;
                    event_parent[top] = u;
                    event_exit[top] = false;
                    top += 1;
                }
            }
        }
    }

    var queries: [max_q]Query = undefined;
    var block_size: usize = 1;
    while ((block_size + 1) * (block_size + 1) <= 2 * n) : (block_size += 1) {}
    for (0..q) |id| {
        var u = query_u[id];
        var v = query_v[id];
        if (entry[u] > entry[v]) {
            const temporary = u;
            u = v;
            v = temporary;
        }
        const ancestor = lca(u, v, &parent, &depth);
        const left = if (ancestor == u) entry[u] else leave[u];
        const right = entry[v];
        const block = left / block_size;
        const right_key = if (block % 2 == 0) right else 2 * n - 1 - right;
        queries[id] = .{ .left = left, .right = right, .id = id, .block = block, .right_key = right_key };
    }
    sortQueries(&queries, q);

    var counts: [max_n]usize = @splat(0);
    var active: [max_n]bool = @splat(false);
    var answers: [max_q]usize = @splat(0);
    var distinct: usize = 0;
    var left: isize = 0;
    var right: isize = -1;
    for (0..q) |sorted_id| {
        const query = queries[sorted_id];
        while (left > @as(isize, @intCast(query.left))) {
            left -= 1;
            toggle(euler[@intCast(left)], &color_id, &counts, &active, &distinct);
        }
        while (right < @as(isize, @intCast(query.right))) {
            right += 1;
            toggle(euler[@intCast(right)], &color_id, &counts, &active, &distinct);
        }
        while (left < @as(isize, @intCast(query.left))) {
            toggle(euler[@intCast(left)], &color_id, &counts, &active, &distinct);
            left += 1;
        }
        while (right > @as(isize, @intCast(query.right))) {
            toggle(euler[@intCast(right)], &color_id, &counts, &active, &distinct);
            right -= 1;
        }
        const ancestor = lca(query_u[query.id], query_v[query.id], &parent, &depth);
        if (ancestor != query_u[query.id] and ancestor != query_v[query.id]) {
            toggle(ancestor, &color_id, &counts, &active, &distinct);
            answers[query.id] = distinct;
            toggle(ancestor, &color_id, &counts, &active, &distinct);
        } else {
            answers[query.id] = distinct;
        }
    }

    const required = 8 * q;
    if (output_opt == null or capacity < required) return -2;
    const output = output_opt.?;
    for (0..q) |id| storeLe(output, 8 * id, @intCast(answers[id]));
    return @intCast(required);
}
