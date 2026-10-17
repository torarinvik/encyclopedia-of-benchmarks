const INVALID_RESULT: i64 = -1;
const MAX_VERTICES: usize = 64;
const MAX_OUTPUT_BYTES: usize = 1016;

fn writeI64Le(output: []u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

fn makeCode(values: []const i64, n: usize, code: *[MAX_VERTICES]i64) ?usize {
    var adjacency = [_]bool{false} ** (MAX_VERTICES * MAX_VERTICES);
    var degree = [_]usize{0} ** MAX_VERTICES;
    for (0..n - 1) |edge| {
        const raw_u = values[2 + edge * 2];
        const raw_v = values[3 + edge * 2];
        if (raw_u < 0 or raw_v < 0 or raw_u >= @as(i64, @intCast(n)) or raw_v >= @as(i64, @intCast(n)) or raw_u == raw_v) return null;
        const u: usize = @intCast(raw_u);
        const v: usize = @intCast(raw_v);
        if (adjacency[u * MAX_VERTICES + v]) return null;
        adjacency[u * MAX_VERTICES + v] = true;
        adjacency[v * MAX_VERTICES + u] = true;
        degree[u] += 1;
        degree[v] += 1;
    }
    var visited = [_]bool{false} ** MAX_VERTICES;
    var queue = [_]usize{0} ** MAX_VERTICES;
    var head: usize = 0;
    var tail: usize = 0;
    visited[0] = true;
    queue[tail] = 0;
    tail += 1;
    while (head < tail) {
        const u = queue[head];
        head += 1;
        for (0..n) |v| {
            if (adjacency[u * MAX_VERTICES + v] and !visited[v]) {
                visited[v] = true;
                queue[tail] = v;
                tail += 1;
            }
        }
    }
    if (tail != n) return null;

    var active = [_]bool{false} ** MAX_VERTICES;
    for (0..n) |v| active[v] = true;
    var code_length: usize = 0;
    if (n > 2) {
        for (0..n - 2) |step| {
            var leaf: ?usize = null;
            var v = n;
            while (v > 0) {
                v -= 1;
                if (active[v] and degree[v] == 1) { leaf = v; break; }
            }
            const leaf_value = leaf orelse return null;
            var neighbor: ?usize = null;
            for (0..n) |u| if (active[u] and adjacency[leaf_value * MAX_VERTICES + u]) { neighbor = u; break; };
            const neighbor_value = neighbor orelse return null;
            code[step] = @intCast(neighbor_value);
            code_length += 1;
            active[leaf_value] = false;
            adjacency[leaf_value * MAX_VERTICES + neighbor_value] = false;
            adjacency[neighbor_value * MAX_VERTICES + leaf_value] = false;
            degree[neighbor_value] -= 1;
        }
    }
    return code_length;
}

fn addEdge(edges: *[126]i64, index: usize, u: usize, v: usize) void {
    edges[index * 2] = @intCast(@min(u, v));
    edges[index * 2 + 1] = @intCast(@max(u, v));
}

fn makeDecodedEdges(values: []const i64, n: usize, edges: *[126]i64) ?usize {
    var remaining = [_]usize{0} ** MAX_VERTICES;
    for (values[2..]) |raw| {
        if (raw < 0 or raw >= @as(i64, @intCast(n))) return null;
        remaining[@intCast(raw)] += 1;
    }
    var active = [_]bool{false} ** MAX_VERTICES;
    for (0..n) |v| active[v] = true;
    var edge_count: usize = 0;
    for (values[2..]) |raw| {
        var leaf: ?usize = null;
        var v = n;
        while (v > 0) {
            v -= 1;
            if (active[v] and remaining[v] == 0) { leaf = v; break; }
        }
        const leaf_value = leaf orelse return null;
        const vertex: usize = @intCast(raw);
        addEdge(edges, edge_count, leaf_value, vertex);
        edge_count += 1;
        active[leaf_value] = false;
        remaining[vertex] -= 1;
    }
    var first: ?usize = null;
    var v = n;
    while (v > 0) {
        v -= 1;
        if (active[v]) { first = v; break; }
    }
    const first_value = first orelse return null;
    active[first_value] = false;
    var second: ?usize = null;
    v = n;
    while (v > 0) {
        v -= 1;
        if (active[v]) { second = v; break; }
    }
    const second_value = second orelse return null;
    addEdge(edges, edge_count, first_value, second_value);
    edge_count += 1;
    for (1..edge_count) |i| {
        const u = edges[i * 2];
        const w = edges[i * 2 + 1];
        var j = i;
        while (j > 0 and (edges[(j - 1) * 2] > u or
            (edges[(j - 1) * 2] == u and edges[(j - 1) * 2 + 1] > w))) : (j -= 1) {
            edges[j * 2] = edges[(j - 1) * 2];
            edges[j * 2 + 1] = edges[(j - 1) * 2 + 1];
        }
        edges[j * 2] = u;
        edges[j * 2 + 1] = w;
    }
    return edge_count;
}

export fn prufer_code(input: ?[*]const i64, length: usize, output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 2 or length > 129) return INVALID_RESULT;
    const values = input.?[0..length];
    const mode = values[0];
    const raw_n = values[1];
    if (raw_n < 1 or raw_n > 64 or (mode != 0 and mode != 1)) return INVALID_RESULT;
    const n: usize = @intCast(raw_n);
    if (mode == 0) {
        if (length != 2 * n) return INVALID_RESULT;
        var code = [_]i64{0} ** MAX_VERTICES;
        const code_length = makeCode(values, n, &code) orelse return INVALID_RESULT;
        const needed = code_length * 8;
        if (needed == 0) return 0;
        if (output == null or capacity < needed) return -2;
        const result = output.?[0..needed];
        for (0..code_length) |i| writeI64Le(result, i * 8, code[i]);
        return @intCast(needed);
    }
    if (n < 2 or length != n) return INVALID_RESULT;
    var edges = [_]i64{0} ** 126;
    const edge_count = makeDecodedEdges(values, n, &edges) orelse return INVALID_RESULT;
    const needed = 8 + edge_count * 16;
    if (needed > MAX_OUTPUT_BYTES) return INVALID_RESULT;
    if (output == null or capacity < needed) return -2;
    const result = output.?[0..needed];
    writeI64Le(result, 0, @intCast(edge_count));
    for (0..edge_count) |i| {
        writeI64Le(result, 8 + i * 16, edges[i * 2]);
        writeI64Le(result, 16 + i * 16, edges[i * 2 + 1]);
    }
    return @intCast(needed);
}
