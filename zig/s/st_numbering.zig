const MAX_VERTICES: usize = 8;
const MAX_EDGES: usize = 28;
const MAX_ARCS: usize = 2 * MAX_EDGES;
const MAX_INPUT: usize = 4 + 2 * MAX_EDGES;

export fn st_numbering(
    input_opt: ?[*]const i64,
    input_length: usize,
    output_opt: ?[*]u8,
    output_capacity: usize,
) i64 {
    if (input_opt == null or input_length < 4 or input_length > MAX_INPUT) return -1;
    const input = input_opt.?;
    const n_value = input[0];
    const m_value = input[1];
    const s_value = input[2];
    const t_value = input[3];
    if (n_value < 2 or n_value > MAX_VERTICES or m_value < 0 or m_value > MAX_EDGES or
        s_value < 0 or s_value >= n_value or t_value < 0 or t_value >= n_value or
        s_value == t_value) return -1;
    const n: usize = @intCast(n_value);
    const m: usize = @intCast(m_value);
    const s: usize = @intCast(s_value);
    const t: usize = @intCast(t_value);
    if (input_length != 4 + 2 * m) return -1;

    var edge_u: [MAX_EDGES]usize = @splat(0);
    var edge_v: [MAX_EDGES]usize = @splat(0);
    var adjacent: [MAX_VERTICES]u16 = @splat(0);
    var st_edge: usize = MAX_EDGES;
    for (0..m) |edge| {
        const u_value = input[4 + 2 * edge];
        const v_value = input[5 + 2 * edge];
        if (u_value < 0 or u_value >= n_value or v_value < 0 or v_value >= n_value or u_value == v_value) return -1;
        const u: usize = @intCast(u_value);
        const v: usize = @intCast(v_value);
        const u_bit: u16 = @as(u16, 1) << @intCast(v);
        const v_bit: u16 = @as(u16, 1) << @intCast(u);
        if (adjacent[u] & u_bit != 0) return -1;
        adjacent[u] |= u_bit;
        adjacent[v] |= v_bit;
        edge_u[edge] = u;
        edge_v[edge] = v;
        if ((u == s and v == t) or (u == t and v == s)) st_edge = edge;
    }
    if (st_edge == MAX_EDGES) return -1;

    var head: [MAX_VERTICES]i32 = @splat(-1);
    var arc_to: [MAX_ARCS]usize = @splat(0);
    var arc_next: [MAX_ARCS]i32 = @splat(-1);
    var arc_count: usize = 0;
    for (0..m) |edge| {
        if (edge == st_edge) continue;
        const u = edge_u[edge];
        const v = edge_v[edge];
        arc_to[arc_count] = v;
        arc_next[arc_count] = head[u];
        head[u] = @intCast(arc_count);
        arc_count += 1;
        arc_to[arc_count] = u;
        arc_next[arc_count] = head[v];
        head[v] = @intCast(arc_count);
        arc_count += 1;
    }
    arc_to[arc_count] = t;
    arc_next[arc_count] = head[s];
    head[s] = @intCast(arc_count);
    arc_count += 1;
    arc_to[arc_count] = s;
    arc_next[arc_count] = head[t];
    head[t] = @intCast(arc_count);

    var parent: [MAX_VERTICES]i32 = @splat(-1);
    var discovery: [MAX_VERTICES]usize = @splat(0);
    var low_vertex: [MAX_VERTICES]usize = @splat(0);
    var children: [MAX_VERTICES]usize = @splat(0);
    var next_arc: [MAX_VERTICES]i32 = @splat(-1);
    var preorder: [MAX_VERTICES]usize = @splat(0);
    for (0..n) |vertex| low_vertex[vertex] = vertex;
    var stack: [MAX_VERTICES]usize = @splat(0);
    var top: usize = 0;
    var clock: usize = 1;
    var preorder_count: usize = 1;
    discovery[s] = clock;
    preorder[0] = s;
    next_arc[s] = head[s];
    stack[top] = s;
    top += 1;
    while (top > 0) {
        const vertex = stack[top - 1];
        const arc_value = next_arc[vertex];
        if (arc_value < 0) {
            top -= 1;
            const ancestor_value = parent[vertex];
            if (ancestor_value >= 0) {
                const ancestor: usize = @intCast(ancestor_value);
                if (discovery[low_vertex[vertex]] < discovery[low_vertex[ancestor]])
                    low_vertex[ancestor] = low_vertex[vertex];
            }
            continue;
        }
        const arc: usize = @intCast(arc_value);
        next_arc[vertex] = arc_next[arc];
        const neighbor = arc_to[arc];
        if (parent[vertex] >= 0 and neighbor == @as(usize, @intCast(parent[vertex]))) continue;
        if (discovery[neighbor] == 0) {
            parent[neighbor] = @intCast(vertex);
            children[vertex] += 1;
            clock += 1;
            discovery[neighbor] = clock;
            low_vertex[neighbor] = neighbor;
            preorder[preorder_count] = neighbor;
            preorder_count += 1;
            next_arc[neighbor] = head[neighbor];
            stack[top] = neighbor;
            top += 1;
        } else if (discovery[neighbor] < discovery[vertex] and
            discovery[neighbor] < discovery[low_vertex[vertex]]) {
            low_vertex[vertex] = neighbor;
        }
    }
    if (preorder_count != n or children[s] != 1) return -1;
    for (0..n) |vertex| {
        if (vertex == s) continue;
        for (0..n) |child| {
            if (parent[child] == @as(i32, @intCast(vertex)) and
                discovery[low_vertex[child]] >= discovery[vertex]) return -1;
        }
    }

    var previous: [MAX_VERTICES]i32 = @splat(-1);
    var following: [MAX_VERTICES]i32 = @splat(-1);
    var sign: [MAX_VERTICES]i8 = @splat(0);
    sign[s] = -1;
    following[s] = @intCast(t);
    previous[t] = @intCast(s);
    var list_head = s;
    for (2..n) |order| {
        const vertex = preorder[order];
        const ancestor: usize = @intCast(parent[vertex]);
        if (sign[low_vertex[vertex]] == -1) {
            const left = previous[ancestor];
            previous[vertex] = left;
            following[vertex] = @intCast(ancestor);
            previous[ancestor] = @intCast(vertex);
            if (left >= 0) {
                following[@intCast(left)] = @intCast(vertex);
            } else {
                list_head = vertex;
            }
            sign[ancestor] = 1;
        } else {
            const right = following[ancestor];
            previous[vertex] = @intCast(ancestor);
            following[vertex] = right;
            following[ancestor] = @intCast(vertex);
            if (right >= 0) previous[@intCast(right)] = @intCast(vertex);
            sign[ancestor] = -1;
        }
    }

    var rank: [MAX_VERTICES]usize = @splat(0);
    var staged: [MAX_VERTICES]u8 = @splat(0);
    var rank_value: usize = 1;
    var vertex_value: i32 = @intCast(list_head);
    while (vertex_value >= 0 and rank_value <= n) {
        const vertex: usize = @intCast(vertex_value);
        rank[vertex] = rank_value;
        staged[vertex] = @intCast(rank_value);
        rank_value += 1;
        vertex_value = following[vertex];
    }
    if (rank_value != n + 1 or rank[s] != 1 or rank[t] != n) return -1;
    for (0..n) |v| {
        if (v == s or v == t) continue;
        var lower = false;
        var higher = false;
        var arc_value = head[v];
        while (arc_value >= 0) {
            const neighbor = arc_to[@intCast(arc_value)];
            lower = lower or rank[neighbor] < rank[v];
            higher = higher or rank[neighbor] > rank[v];
            arc_value = arc_next[@intCast(arc_value)];
        }
        if (!lower or !higher) return -1;
    }
    if (output_opt == null or output_capacity < n) return -2;
    const output = output_opt.?;
    for (0..n) |v| output[v] = staged[v];
    return @intCast(n);
}
