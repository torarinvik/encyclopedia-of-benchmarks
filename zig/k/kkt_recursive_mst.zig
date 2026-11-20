const MAX_N: usize = 16;
const MAX_M: usize = 16;
const MAX_INPUT: usize = 52;

const Edge = struct { u: usize = 0, v: usize = 0, weight: i64 = 0, id: usize = 0 };

fn edgeLess(a: Edge, b: Edge) bool {
    if (a.weight != b.weight) return a.weight < b.weight;
    return a.id < b.id;
}

fn splitmix64(state: *u64) u64 {
    state.* +%= 0x9E3779B97F4A7C15;
    var z = state.*;
    z = (z ^ (z >> 30)) *% 0xBF58476D1CE4E5B9;
    z = (z ^ (z >> 27)) *% 0x94D049BB133111EB;
    return z ^ (z >> 31);
}

fn root(parent: *[MAX_N]usize, node0: usize) usize {
    var node = node0;
    while (parent[node] != node) {
        parent[node] = parent[parent[node]];
        node = parent[node];
    }
    return node;
}

fn sortEdges(edges: *[MAX_M]Edge, count: usize) void {
    for (1..count) |i| {
        const key = edges[i];
        var position = i;
        while (position > 0 and edgeLess(key, edges[position - 1])) {
            edges[position] = edges[position - 1];
            position -= 1;
        }
        edges[position] = key;
    }
}

fn boruvkaPhase(n: *usize, edges: *[MAX_M]Edge, edge_count: *usize, selected_mask: *u64) void {
    if (edge_count.* == 0) return;
    var best: [MAX_N]isize = @splat(-1);
    for (0..n.*) |vertex| {
        for (0..edge_count.*) |index| {
            const edge = edges[index];
            if (edge.u != vertex and edge.v != vertex) continue;
            if (best[vertex] < 0 or edgeLess(edge, edges[@intCast(best[vertex])])) best[vertex] = @intCast(index);
        }
    }

    var parent: [MAX_N]usize = @splat(0);
    for (0..n.*) |vertex| parent[vertex] = vertex;
    for (0..n.*) |vertex| {
        if (best[vertex] < 0) continue;
        const edge = edges[@intCast(best[vertex])];
        selected_mask.* |= @as(u64, 1) << @intCast(edge.id);
        const a = root(&parent, edge.u);
        const b = root(&parent, edge.v);
        if (a != b) parent[a] = b;
    }

    var root_to_local: [MAX_N]isize = @splat(-1);
    var local_of: [MAX_N]usize = @splat(0);
    var contracted_n: usize = 0;
    for (0..n.*) |vertex| {
        const representative = root(&parent, vertex);
        if (root_to_local[representative] < 0) {
            root_to_local[representative] = @intCast(contracted_n);
            contracted_n += 1;
        }
        local_of[vertex] = @intCast(root_to_local[representative]);
    }

    var contracted: [MAX_M]Edge = @splat(.{});
    var contracted_count: usize = 0;
    for (0..edge_count.*) |index| {
        var edge = edges[index];
        var a = local_of[edge.u];
        var b = local_of[edge.v];
        if (a == b) continue;
        if (a > b) { const temporary = a; a = b; b = temporary; }
        edge.u = a;
        edge.v = b;
        var duplicate: ?usize = null;
        for (0..contracted_count) |j| {
            if (contracted[j].u == a and contracted[j].v == b) { duplicate = j; break; }
        }
        if (duplicate) |j| {
            if (edgeLess(edge, contracted[j])) contracted[j] = edge;
        } else {
            contracted[contracted_count] = edge;
            contracted_count += 1;
        }
    }
    n.* = contracted_n;
    edge_count.* = contracted_count;
    edges.* = contracted;
}

fn samplePathMax(n: usize, sample: *const [MAX_M]Edge, sample_count: usize, forest_mask: u64,
                 start: usize, target: usize, max_weight_out: *i64, max_id_out: *usize) bool {
    if (start >= n or target >= n) return false;
    var seen: [MAX_N]bool = @splat(false);
    var stack: [MAX_N]usize = @splat(0);
    var has_max: [MAX_N]bool = @splat(false);
    var max_weight: [MAX_N]i64 = @splat(0);
    var max_id: [MAX_N]usize = @splat(0);
    var top: usize = 1;
    stack[0] = start;
    seen[start] = true;
    while (top > 0 and !seen[target]) {
        top -= 1;
        const current = stack[top];
        for (0..sample_count) |index| {
            const edge = sample[index];
            if ((forest_mask & (@as(u64, 1) << @intCast(edge.id))) == 0) continue;
            var neighbor: ?usize = null;
            if (edge.u == current) neighbor = edge.v else if (edge.v == current) neighbor = edge.u;
            if (neighbor) |next| {
                if (seen[next]) continue;
                seen[next] = true;
                stack[top] = next;
                top += 1;
                var path_weight = edge.weight;
                var path_id = edge.id;
                if (has_max[current]) {
                    path_weight = max_weight[current];
                    path_id = max_id[current];
                    if (edge.weight > path_weight or (edge.weight == path_weight and edge.id > path_id)) {
                        path_weight = edge.weight;
                        path_id = edge.id;
                    }
                }
                has_max[next] = true;
                max_weight[next] = path_weight;
                max_id[next] = path_id;
            }
        }
    }
    if (!seen[target]) return false;
    max_weight_out.* = max_weight[target];
    max_id_out.* = max_id[target];
    return true;
}

fn kktRecursive(n_input: usize, edge_count_input: usize, input_edges: [MAX_M]Edge, state: *u64) u64 {
    if (edge_count_input == 0) return 0;
    var n = n_input;
    var edge_count = edge_count_input;
    var edges = input_edges;
    var selected_mask: u64 = 0;
    boruvkaPhase(&n, &edges, &edge_count, &selected_mask);
    if (edge_count == 0) return selected_mask;
    boruvkaPhase(&n, &edges, &edge_count, &selected_mask);
    if (edge_count == 0) return selected_mask;
    sortEdges(&edges, edge_count);

    var sample: [MAX_M]Edge = @splat(.{});
    var sample_count: usize = 0;
    for (0..edge_count) |index| {
        if ((splitmix64(state) & 1) != 0) {
            sample[sample_count] = edges[index];
            sample_count += 1;
        }
    }
    const forest_mask = kktRecursive(n, sample_count, sample, state);

    var light: [MAX_M]Edge = @splat(.{});
    var light_count: usize = 0;
    for (0..edge_count) |index| {
        const edge = edges[index];
        var path_weight: i64 = 0;
        var path_id: usize = 0;
        const connected = samplePathMax(n, &sample, sample_count, forest_mask, edge.u, edge.v, &path_weight, &path_id);
        const is_heavy = connected and (edge.weight > path_weight or (edge.weight == path_weight and edge.id > path_id));
        if (!is_heavy) {
            light[light_count] = edge;
            light_count += 1;
        }
    }
    return selected_mask | kktRecursive(n, light_count, light, state);
}

export fn kkt_recursive_mst(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 3 or length > MAX_INPUT) return -1;
    const input = input_opt.?;
    const n64 = input[0];
    const m64 = input[1];
    const seed = input[2];
    if (n64 < 1 or n64 > @as(i64, @intCast(MAX_N)) or m64 < 0 or m64 > @as(i64, @intCast(MAX_M)) or seed < 0) return -1;
    const n: usize = @intCast(n64);
    const m: usize = @intCast(m64);
    if (length != 3 + 3 * m) return -1;
    var edges: [MAX_M]Edge = @splat(.{});
    for (0..m) |index| {
        const u64 = input[3 + 3 * index];
        const v64 = input[4 + 3 * index];
        const weight = input[5 + 3 * index];
        if (u64 < 0 or u64 >= v64 or v64 >= n64 or weight < 0 or weight > 255) return -1;
        const u: usize = @intCast(u64);
        const v: usize = @intCast(v64);
        for (0..index) |previous| {
            if (edges[previous].u == u and edges[previous].v == v) return -1;
        }
        edges[index] = .{ .u = u, .v = v, .weight = weight, .id = index };
    }
    var state: u64 = @intCast(seed);
    return @intCast(kktRecursive(n, m, edges, &state));
}
