const MAX_N: usize = 16;
const MAX_EDGES: usize = MAX_N - 1;
const MAX_ARCS: usize = 2 * MAX_EDGES;
const MAX_INPUT_LENGTH: usize = 48;

fn findRoot(sets: *[MAX_N]i32, vertex_value: usize) usize {
    var vertex = vertex_value;
    while (sets.*[vertex] != @as(i32, @intCast(vertex))) {
        sets.*[vertex] = sets.*[@intCast(sets.*[vertex])];
        vertex = @intCast(sets.*[vertex]);
    }
    return vertex;
}

fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn tree_random_walk_edge_hitting_cost(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > MAX_INPUT_LENGTH) return -1;
    const input = input_opt.?;
    const n_value = input[0];
    const root_value = input[1];
    if (n_value < 1 or n_value > @as(i64, @intCast(MAX_N))
            or root_value < 0 or root_value >= n_value) return -1;
    const n: usize = @intCast(n_value);
    const root: usize = @intCast(root_value);
    const edge_count = n - 1;
    if (length != 2 + 3 * edge_count) return -1;

    var head: [MAX_N]i32 = @splat(-1);
    var to: [MAX_ARCS]i32 = @splat(0);
    var next_arc: [MAX_ARCS]i32 = @splat(0);
    var sets: [MAX_N]i32 = @splat(0);
    var input_u: [MAX_EDGES]usize = @splat(0);
    var input_v: [MAX_EDGES]usize = @splat(0);
    var incident_sum: [MAX_N]i64 = @splat(0);
    var down: [MAX_N]i64 = @splat(0);
    var up: [MAX_N]i64 = @splat(0);
    for (0..n) |vertex| sets[vertex] = @intCast(vertex);

    var arc_count: usize = 0;
    for (0..edge_count) |edge| {
        const offset = 2 + 3 * edge;
        const u_value = input[offset];
        const v_value = input[offset + 1];
        const weight = input[offset + 2];
        if (u_value < 0 or u_value >= n_value or v_value < 0 or v_value >= n_value
                or u_value == v_value or weight < 1 or weight > 9) return -1;
        const u: usize = @intCast(u_value);
        const v: usize = @intCast(v_value);
        const set_u = findRoot(&sets, u);
        const set_v = findRoot(&sets, v);
        if (set_u == set_v) return -1;
        sets[set_v] = @intCast(set_u);
        input_u[edge] = u;
        input_v[edge] = v;
        to[arc_count] = @intCast(v);
        next_arc[arc_count] = head[u];
        head[u] = @intCast(arc_count);
        arc_count += 1;
        to[arc_count] = @intCast(u);
        next_arc[arc_count] = head[v];
        head[v] = @intCast(arc_count);
        arc_count += 1;
        incident_sum[u] += weight;
        incident_sum[v] += weight;
    }

    const output_bytes = 16 * edge_count;
    if (output_opt == null or capacity < output_bytes) return -2;
    const output = output_opt.?;

    var parent: [MAX_N]i32 = @splat(-1);
    var order: [MAX_N]usize = @splat(0);
    parent[root] = @intCast(root);
    order[0] = root;
    var order_size: usize = 1;
    var cursor: usize = 0;
    while (cursor < order_size) : (cursor += 1) {
        const vertex = order[cursor];
        var arc = head[vertex];
        while (arc >= 0) {
            const index: usize = @intCast(arc);
            const neighbor: usize = @intCast(to[index]);
            if (parent[neighbor] == -1) {
                parent[neighbor] = @intCast(vertex);
                order[order_size] = neighbor;
                order_size += 1;
            }
            arc = next_arc[index];
        }
    }
    var position = n;
    while (position > 0) {
        position -= 1;
        const vertex = order[position];
        down[vertex] = incident_sum[vertex];
        var arc = head[vertex];
        while (arc >= 0) {
            const index: usize = @intCast(arc);
            const child: usize = @intCast(to[index]);
            if (parent[child] == @as(i32, @intCast(vertex))) down[vertex] += down[child];
            arc = next_arc[index];
        }
    }
    for (0..n) |position_index| {
        const vertex = order[position_index];
        var arc = head[vertex];
        while (arc >= 0) {
            const index: usize = @intCast(arc);
            const child: usize = @intCast(to[index]);
            if (parent[child] == @as(i32, @intCast(vertex)))
                up[child] = up[vertex] + down[vertex] - down[child];
            arc = next_arc[index];
        }
    }
    for (0..edge_count) |edge| {
        const u = input_u[edge];
        const v = input_v[edge];
        const u_is_child = parent[u] == @as(i32, @intCast(v));
        const toward_v = if (u_is_child) down[u] else up[v];
        const toward_u = if (u_is_child) up[u] else down[v];
        storeI64Le(output, 16 * edge, toward_v);
        storeI64Le(output, 16 * edge + 8, toward_u);
    }
    return @intCast(output_bytes);
}
