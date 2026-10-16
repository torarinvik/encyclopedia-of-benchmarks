/// BFS two-coloring for a bounded undirected graph.
const MAX_VERTICES: usize = 64;
const MAX_EDGES: usize = 256;
const MAX_INPUT_LENGTH: usize = 2 + 2 * MAX_EDGES;

export fn is_graph_bipartite(values: ?[*]const i64, length: usize) i64 {
    if (values == null or length < 2 or length > MAX_INPUT_LENGTH) return -1;
    const input = values.?;
    const vertex_count_raw = input[0];
    const edge_count_raw = input[1];
    if (vertex_count_raw < 0 or vertex_count_raw > MAX_VERTICES or
        edge_count_raw < 0 or edge_count_raw > MAX_EDGES or
        length != 2 + 2 * @as(usize, @intCast(edge_count_raw))) return -1;
    const vertex_count: usize = @intCast(vertex_count_raw);
    const edge_count: usize = @intCast(edge_count_raw);

    var head = [_]i32{-1} ** MAX_VERTICES;
    var arc_to = [_]i32{0} ** (2 * MAX_EDGES);
    var arc_next = [_]i32{0} ** (2 * MAX_EDGES);
    var side = [_]i32{-1} ** MAX_VERTICES;
    var queue = [_]usize{0} ** MAX_VERTICES;
    var arc_count: usize = 0;
    for (0..edge_count) |edge| {
        const u_raw = input[2 + 2 * edge];
        const v_raw = input[3 + 2 * edge];
        if (u_raw < 1 or u_raw > vertex_count_raw or v_raw < 1 or v_raw > vertex_count_raw) return -1;
        const u: usize = @intCast(u_raw - 1);
        const v: usize = @intCast(v_raw - 1);
        arc_to[arc_count] = @intCast(v);
        arc_next[arc_count] = head[u];
        head[u] = @intCast(arc_count);
        arc_count += 1;
        arc_to[arc_count] = @intCast(u);
        arc_next[arc_count] = head[v];
        head[v] = @intCast(arc_count);
        arc_count += 1;
    }

    var bipartite = true;
    for (0..vertex_count) |start| {
        if (side[start] != -1) continue;
        var queue_head: usize = 0;
        var queue_tail: usize = 1;
        queue[0] = start;
        side[start] = 0;
        while (queue_head < queue_tail) {
            const current = queue[queue_head];
            queue_head += 1;
            var arc = head[current];
            while (arc != -1) {
                const neighbor: usize = @intCast(arc_to[@intCast(arc)]);
                if (side[neighbor] == -1) {
                    side[neighbor] = side[current] ^ 1;
                    queue[queue_tail] = neighbor;
                    queue_tail += 1;
                } else if (side[neighbor] == side[current]) {
                    bipartite = false;
                }
                arc = arc_next[@intCast(arc)];
            }
        }
    }
    return if (bipartite) 1 else 0;
}
