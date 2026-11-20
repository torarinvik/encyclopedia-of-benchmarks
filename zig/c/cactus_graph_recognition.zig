const MaxN: usize = 32;
const MaxM: usize = 128;
const MaxInput: usize = 259;
const MaxArcs: usize = 256;

export fn cactus_graph_recognition(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 2 or length > MaxInput) return -1;
    const input = input_opt.?[0..length];
    if (input[0] < 1 or input[0] > @as(i64, @intCast(MaxN)) or input[1] < 0 or
        input[1] > @as(i64, @intCast(MaxM))) return -1;
    const n: usize = @intCast(input[0]);
    const m: usize = @intCast(input[1]);
    if (length != 2 + 2 * m) return -1;

    var edge_seen: [MaxN * MaxN]bool = @splat(false);
    var head: [MaxN]i32 = @splat(-1);
    var arc_to: [MaxArcs]i32 = undefined;
    var arc_edge: [MaxArcs]i32 = undefined;
    var next_arc: [MaxArcs]i32 = undefined;
    var arc_count: usize = 0;
    for (0..m) |e| {
        const u_value = input[2 + 2 * e];
        const v_value = input[3 + 2 * e];
        if (u_value < 0 or u_value >= @as(i64, @intCast(n)) or v_value < 0 or
            v_value >= @as(i64, @intCast(n)) or u_value == v_value) return -1;
        const u: usize = @intCast(u_value);
        const v: usize = @intCast(v_value);
        if (edge_seen[u * MaxN + v]) return -1;
        edge_seen[u * MaxN + v] = true;
        edge_seen[v * MaxN + u] = true;
        arc_to[arc_count] = @intCast(v); arc_edge[arc_count] = @intCast(e);
        next_arc[arc_count] = head[u]; head[u] = @intCast(arc_count); arc_count += 1;
        arc_to[arc_count] = @intCast(u); arc_edge[arc_count] = @intCast(e);
        next_arc[arc_count] = head[v]; head[v] = @intCast(arc_count); arc_count += 1;
    }

    var state: [MaxN]u8 = @splat(0);
    var parent: [MaxN]i32 = @splat(-1);
    var parent_edge: [MaxN]i32 = @splat(-1);
    var depth: [MaxN]usize = @splat(0);
    var cursor: [MaxN]i32 = @splat(-1);
    var stack: [MaxN]usize = undefined;
    var cycle_of: [MaxM]i32 = @splat(-1);
    var used: [MaxM]bool = @splat(false);
    var cycle_vertices: [MaxN]usize = @splat(0);
    var cycles: usize = 0;
    var edge_cactus = true;
    var vertex_cactus = true;
    for (0..n) |root| {
        if (!edge_cactus) break;
        if (state[root] != 0) continue;
        var top: usize = 1;
        state[root] = 1; cursor[root] = head[root]; stack[0] = root;
        while (top > 0 and edge_cactus) {
            const u = stack[top - 1];
            const arc_value = cursor[u];
            if (arc_value < 0) { state[u] = 2; top -= 1; continue; }
            const arc: usize = @intCast(arc_value);
            cursor[u] = next_arc[arc];
            const e: usize = @intCast(arc_edge[arc]);
            if (used[e]) continue;
            used[e] = true;
            const v: usize = @intCast(arc_to[arc]);
            if (state[v] == 0) {
                parent[v] = @intCast(u); parent_edge[v] = @intCast(e); depth[v] = depth[u] + 1;
                state[v] = 1; cursor[v] = head[v]; stack[top] = v; top += 1;
            } else if (state[v] == 1 and depth[v] < depth[u]) {
                var x = u;
                while (x != v) {
                    const tree_edge_value = parent_edge[x];
                    if (tree_edge_value < 0 or cycle_of[@intCast(tree_edge_value)] != -1) {
                        edge_cactus = false;
                        break;
                    }
                    x = @intCast(parent[x]);
                }
                if (!edge_cactus) break;
                x = u;
                cycle_vertices[x] += 1;
                if (cycle_vertices[x] > 1) vertex_cactus = false;
                while (x != v) {
                    const tree_edge: usize = @intCast(parent_edge[x]);
                    cycle_of[tree_edge] = @intCast(cycles);
                    x = @intCast(parent[x]);
                    cycle_vertices[x] += 1;
                    if (cycle_vertices[x] > 1) vertex_cactus = false;
                }
                cycle_of[e] = @intCast(cycles);
                cycles += 1;
            }
        }
    }
    if (!edge_cactus) return 0;
    return @intCast(4 * cycles + (if (vertex_cactus) @as(usize, 2) else 0) + 1);
}
