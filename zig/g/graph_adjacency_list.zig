fn vertexIndex(order: *const [32]i64, count: usize, value: i64) ?usize {
    for (0..count) |i| if (order[i] == value) return i;
    return null;
}

fn neighborIndex(rows: *const [32][34]i64, degree: *const [32]usize, from: usize, to: i64) ?usize {
    for (0..degree[from]) |i| if (rows[from][i] == to) return i;
    return null;
}

fn eraseNeighbor(rows: *[32][34]i64, degree: *[32]usize, from: usize, at: usize) void {
    var i = at;
    while (i + 1 < degree[from]) : (i += 1) rows[from][i] = rows[from][i + 1];
    degree[from] -= 1;
}

fn validId(value: i64) bool { return value >= 0 and value < 32; }

fn putI64Le(output: [*c]u8, word: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[word * 8 + byte] = @truncate(bits >> @as(u6, @intCast(byte * 8)));
}

export fn graph_adjacency_list(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 4) return -1;
    const directed = input[0];
    const initial_count = input[1];
    if ((directed != 0 and directed != 1) or initial_count < 0 or initial_count > 32 or
        length < 4 + @as(usize, @intCast(initial_count))) return -1;

    var order: [32]i64 = @splat(0);
    var rows: [32][34]i64 = @splat(@splat(0));
    var degree: [32]usize = @splat(0);
    var count: usize = @intCast(initial_count);
    var cursor: usize = 2;
    for (0..count) |i| {
        const vertex = input[cursor]; cursor += 1;
        if (!validId(vertex) or vertexIndex(&order, i, vertex) != null) return -1;
        order[i] = vertex;
    }
    const edge_count = input[cursor]; cursor += 1;
    if (edge_count < 0 or edge_count > 1024 or
        length < cursor + 2 * @as(usize, @intCast(edge_count)) + 1) return -1;
    for (0..@as(usize, @intCast(edge_count))) |_| {
        const from_value = input[cursor]; const to_value = input[cursor + 1]; cursor += 2;
        if (!validId(from_value) or !validId(to_value)) return -1;
        const from: usize = @intCast(from_value);
        const to: usize = @intCast(to_value);
        if (vertexIndex(&order, count, from_value) == null or vertexIndex(&order, count, to_value) == null or
            neighborIndex(&rows, &degree, from, to_value) != null) return -1;
        rows[from][degree[from]] = to_value; degree[from] += 1;
        if (directed == 0) { rows[to][degree[to]] = from_value; degree[to] += 1; }
    }
    const operation_count = input[cursor]; cursor += 1;
    if (operation_count < 0 or operation_count > 64 or
        length != cursor + 3 * @as(usize, @intCast(operation_count))) return -1;
    var results: [64]i64 = @splat(0);
    for (0..@as(usize, @intCast(operation_count))) |i| {
        const op = input[cursor]; const a = input[cursor + 1]; const b = input[cursor + 2]; cursor += 3;
        if (op == 0) {
            if (!validId(a) or b != 0 or vertexIndex(&order, count, a) != null or count >= 32) return -1;
            order[count] = a; count += 1; degree[@intCast(a)] = 0; results[i] = 1;
        } else if (op == 1) {
            if (!validId(a) or b != 0) return -1;
            const vertex: usize = @intCast(a);
            const at = vertexIndex(&order, count, a) orelse return -1;
            if (directed == 1) {
                for (0..count) |u| {
                    const source: usize = @intCast(order[u]);
                    while (neighborIndex(&rows, &degree, source, a)) |edge| eraseNeighbor(&rows, &degree, source, edge);
                }
            } else {
                while (degree[vertex] > 0) {
                    const neighbor: usize = @intCast(rows[vertex][degree[vertex] - 1]); degree[vertex] -= 1;
                    if (neighbor != vertex) if (neighborIndex(&rows, &degree, neighbor, a)) |edge| eraseNeighbor(&rows, &degree, neighbor, edge);
                }
            }
            for (at..count - 1) |j| order[j] = order[j + 1];
            degree[vertex] = 0; count -= 1; results[i] = 1;
        } else if (op == 2 or op == 3 or op == 5) {
            if (!validId(a) or !validId(b)) return -1;
            const from: usize = @intCast(a); const to: usize = @intCast(b);
            if (vertexIndex(&order, count, a) == null or vertexIndex(&order, count, b) == null) return -1;
            const edge = neighborIndex(&rows, &degree, from, b);
            if (op == 5) {
                results[i] = if (edge != null) 1 else 0;
            } else if (op == 2) {
                if (edge != null or degree[from] >= 34 or (directed == 0 and degree[to] >= 34)) return -1;
                rows[from][degree[from]] = b; degree[from] += 1;
                if (directed == 0) { rows[to][degree[to]] = a; degree[to] += 1; }
                results[i] = 1;
            } else {
                const index = edge orelse return -1;
                eraseNeighbor(&rows, &degree, from, index);
                if (directed == 0) { const reverse = neighborIndex(&rows, &degree, to, a) orelse return -1; eraseNeighbor(&rows, &degree, to, reverse); }
                results[i] = 1;
            }
        } else if (op == 4) {
            if (!validId(a) or b != 0) return -1;
            results[i] = if (vertexIndex(&order, count, a) != null) 1 else 0;
        } else if (op == 6) {
            if (a != 0 or b != 0) return -1;
            count = 0; degree = @splat(0); results[i] = 1;
        } else return -1;
    }
    var words: usize = 2 + @as(usize, @intCast(operation_count));
    for (0..count) |i| words += 2 + degree[@intCast(order[i])];
    if (output == null or capacity < words * 8) return -2;
    var word: usize = 0;
    putI64Le(output, word, operation_count); word += 1;
    for (0..@as(usize, @intCast(operation_count))) |i| { putI64Le(output, word, results[i]); word += 1; }
    putI64Le(output, word, @intCast(count)); word += 1;
    for (0..count) |i| {
        const vertex: usize = @intCast(order[i]);
        putI64Le(output, word, order[i]); word += 1;
        putI64Le(output, word, @intCast(degree[vertex])); word += 1;
        for (0..degree[vertex]) |j| { putI64Le(output, word, rows[vertex][j]); word += 1; }
    }
    return @intCast(words * 8);
}
