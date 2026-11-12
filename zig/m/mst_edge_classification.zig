const MAX_VERTICES: usize = 12;
const MAX_EDGES: usize = 24;
const MAX_INPUT_LENGTH: usize = 2 + 3 * MAX_EDGES + 1;

fn findRoot(parent: []usize, vertex: usize) usize {
    var root = vertex;
    while (parent[root] != root) { root = parent[root]; }
    var current = vertex;
    while (parent[current] != current) {
        const next = parent[current];
        parent[current] = root;
        current = next;
    }
    return root;
}

fn joinRoots(parent: []usize, left: usize, right: usize) void {
    const a = findRoot(parent, left);
    const b = findRoot(parent, right);
    if (a != b) parent[b] = a;
}

fn alternativePathExists(left: []const usize, right: []const usize,
    edge_id: []const usize, omitted: usize, source: usize, target: usize) bool {
    var seen = [_]bool{false} ** MAX_VERTICES;
    var queue = [_]usize{0} ** MAX_VERTICES;
    var head: usize = 0;
    var tail: usize = 0;
    seen[source] = true;
    queue[tail] = source;
    tail += 1;
    while (head < tail) {
        const vertex = queue[head];
        head += 1;
        if (vertex == target) return true;
        for (0..edge_id.len) |edge| {
            if (edge_id[edge] == omitted) continue;
            const neighbor: usize = if (left[edge] == vertex) right[edge]
                else if (right[edge] == vertex) left[edge]
                else MAX_VERTICES;
            if (neighbor < MAX_VERTICES and !seen[neighbor]) {
                seen[neighbor] = true;
                queue[tail] = neighbor;
                tail += 1;
            }
        }
    }
    return false;
}

export fn mst_edge_classification(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, output_capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > MAX_INPUT_LENGTH) return -1;
    const input = input_opt.?;
    if (input[0] < 1 or input[0] > @as(i64, @intCast(MAX_VERTICES)) or
        input[1] < 0 or input[1] > @as(i64, @intCast(MAX_EDGES))) return -1;
    const vertex_count: usize = @intCast(input[0]);
    const edge_count: usize = @intCast(input[1]);
    if (length != 2 + 3 * edge_count) return -1;

    var left = [_]usize{0} ** MAX_EDGES;
    var right = [_]usize{0} ** MAX_EDGES;
    var weight = [_]usize{0} ** MAX_EDGES;
    var order = [_]usize{0} ** MAX_EDGES;
    var classes = [_]u8{0} ** MAX_EDGES;
    for (0..edge_count) |edge| {
        const u = input[2 + 3 * edge];
        const v = input[3 + 3 * edge];
        const w = input[4 + 3 * edge];
        if (u < 0 or u >= v or v >= @as(i64, @intCast(vertex_count)) or w < 0 or w > 20) return -1;
        left[edge] = @intCast(u);
        right[edge] = @intCast(v);
        weight[edge] = @intCast(w);
        order[edge] = edge;
        for (0..edge) |prior| {
            if (left[prior] == left[edge] and right[prior] == right[edge]) return -1;
        }
    }
    if (edge_count > 1) {
        for (1..edge_count) |i| {
            const item = order[i];
            var j = i;
            while (j > 0 and (weight[order[j - 1]] > weight[item] or
                (weight[order[j - 1]] == weight[item] and order[j - 1] > item))) {
                order[j] = order[j - 1];
                j -= 1;
            }
            order[j] = item;
        }
    }

    var parent = [_]usize{0} ** MAX_VERTICES;
    for (0..vertex_count) |vertex| { parent[vertex] = vertex; }
    var start: usize = 0;
    while (start < edge_count) {
        var stop = start + 1;
        const group_weight = weight[order[start]];
        while (stop < edge_count and weight[order[stop]] == group_weight) { stop += 1; }
        var q_left = [_]usize{0} ** MAX_EDGES;
        var q_right = [_]usize{0} ** MAX_EDGES;
        var q_id = [_]usize{0} ** MAX_EDGES;
        var q_count: usize = 0;
        for (start..stop) |pos| {
            const id = order[pos];
            const a = findRoot(parent[0..vertex_count], left[id]);
            const b = findRoot(parent[0..vertex_count], right[id]);
            if (a != b) {
                q_left[q_count] = a;
                q_right[q_count] = b;
                q_id[q_count] = id;
                q_count += 1;
            }
        }
        for (0..q_count) |edge| {
            classes[q_id[edge]] = if (alternativePathExists(q_left[0..q_count], q_right[0..q_count],
                q_id[0..q_count], q_id[edge], q_left[edge], q_right[edge])) 1 else 2;
        }
        for (start..stop) |pos| {
            const id = order[pos];
            joinRoots(parent[0..vertex_count], left[id], right[id]);
        }
        start = stop;
    }
    const representative = findRoot(parent[0..vertex_count], 0);
    for (1..vertex_count) |vertex| {
        if (findRoot(parent[0..vertex_count], vertex) != representative) return -1;
    }
    if (output_capacity < edge_count or (edge_count > 0 and output_opt == null)) return -2;
    if (edge_count > 0) {
        const output = output_opt.?;
        for (0..edge_count) |edge| { output[edge] = classes[edge]; }
    }
    return @intCast(edge_count);
}
