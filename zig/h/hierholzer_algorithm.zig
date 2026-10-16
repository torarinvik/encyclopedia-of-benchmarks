/// Source-faithful bounded Hierholzer traversal for an undirected multigraph.
fn hashRecord(record: []const i64) i64 {
    var hash: u64 = 14695981039346656037;
    for (record) |word| {
        const bits: u64 = @bitCast(word);
        for (0..8) |byte| {
            hash ^= (bits >> @intCast(byte * 8)) & 255;
            hash *%= 1099511628211;
        }
    }
    return @intCast(hash & 0x7fff_ffff_ffff_ffff);
}

export fn hierholzer_algorithm(input: ?[*]const i64, length: usize) i64 {
    if (input == null or length < 2 or length > 514) return -1;
    const values = input.?;
    const n_raw = values[0];
    const m_raw = values[1];
    if (n_raw < 0 or n_raw > 8 or m_raw < 0 or m_raw > 256) return -1;
    const n: usize = @intCast(n_raw);
    const m: usize = @intCast(m_raw);
    if (length != 2 + 2 * m or (n == 0 and m != 0)) return -1;

    var adjacency = [_][512]usize{[_]usize{0} ** 512} ** 8;
    var degree = [_]usize{0} ** 8;
    for (0..m) |edge| {
        const u_raw = values[2 + 2 * edge];
        const v_raw = values[3 + 2 * edge];
        if (u_raw < 0 or v_raw < 0 or u_raw >= n_raw or v_raw >= n_raw) return -1;
        const u: usize = @intCast(u_raw);
        const v: usize = @intCast(v_raw);
        adjacency[u][degree[u]] = v;
        degree[u] += 1;
        adjacency[v][degree[v]] = u;
        degree[v] += 1;
    }
    if (n == 0) return hashRecord(&[_]i64{ 1, 0 });

    var start: usize = 0;
    var has_edge = false;
    for (0..n) |vertex| {
        if (degree[vertex] > 0 and !has_edge) {
            start = vertex;
            has_edge = true;
        }
    }
    if (!has_edge) return hashRecord(&[_]i64{ 1, 1, 0 });

    var seen = [_]bool{false} ** 8;
    var queue = [_]usize{0} ** 8;
    var head: usize = 0;
    var tail: usize = 1;
    queue[0] = start;
    seen[start] = true;
    while (head < tail) : (head += 1) {
        const vertex = queue[head];
        for (0..n) |other| {
            if (degree[other] > 0 and !seen[other]) {
                for (0..degree[other]) |j| {
                    if (adjacency[other][j] == vertex) {
                        seen[other] = true;
                        queue[tail] = other;
                        tail += 1;
                        break;
                    }
                }
            }
        }
    }
    for (0..n) |vertex| {
        if (degree[vertex] % 2 != 0 or (degree[vertex] > 0 and !seen[vertex])) return hashRecord(&[_]i64{ 0, 0 });
    }

    var lengths = degree;
    var stack = [_]usize{0} ** 258;
    var stack_len: usize = 1;
    stack[0] = start;
    var route = [_]usize{0} ** 258;
    var route_len: usize = 0;
    while (stack_len > 0) {
        const vertex = stack[stack_len - 1];
        if (lengths[vertex] > 0) {
            const next = adjacency[vertex][0];
            for (0..lengths[vertex] - 1) |j| adjacency[vertex][j] = adjacency[vertex][j + 1];
            lengths[vertex] -= 1;
            var reciprocal: usize = 0;
            while (reciprocal < lengths[next] and adjacency[next][reciprocal] != vertex) : (reciprocal += 1) {}
            if (reciprocal < lengths[next]) {
                for (reciprocal..lengths[next] - 1) |j| adjacency[next][j] = adjacency[next][j + 1];
                lengths[next] -= 1;
            }
            stack[stack_len] = next;
            stack_len += 1;
        } else {
            stack_len -= 1;
            route[route_len] = vertex;
            route_len += 1;
        }
    }
    if (route_len != m + 1) return hashRecord(&[_]i64{ 0, 0 });
    var record: [258]i64 = undefined;
    record[0] = 1;
    record[1] = @intCast(route_len);
    for (0..route_len) |index| record[2 + index] = @intCast(route[route_len - 1 - index]);
    return hashRecord(record[0 .. 2 + route_len]);
}
