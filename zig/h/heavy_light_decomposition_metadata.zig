const MAX_VERTICES: usize = 128;

fn putI64(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @as(u6, @intCast(8 * byte)));
}

pub export fn heavy_light_decomposition_metadata(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 2) return -1;
    const nv = input[0];
    const mv = input[1];
    if (nv < 1 or nv > 128 or mv != nv - 1 or length != 2 + 2 * @as(usize, @intCast(mv))) return -1;
    const n: usize = @intCast(nv);
    const m: usize = @intCast(mv);
    var adjacency = [_]i32{0} ** (MAX_VERTICES * MAX_VERTICES);
    var degree = [_]usize{0} ** MAX_VERTICES;
    for (0..m) |edge| {
        const uv = input[2 + 2 * edge];
        const vv = input[3 + 2 * edge];
        if (uv < 0 or uv >= nv or vv < 0 or vv >= nv or uv == vv) return -1;
        const u: usize = @intCast(uv);
        const v: usize = @intCast(vv);
        for (0..degree[u]) |i| {
            if (adjacency[u * MAX_VERTICES + i] == @as(i32, @intCast(v))) return -1;
        }
        adjacency[u * MAX_VERTICES + degree[u]] = @intCast(v);
        degree[u] += 1;
        adjacency[v * MAX_VERTICES + degree[v]] = @intCast(u);
        degree[v] += 1;
    }

    var parent = [_]i32{-2} ** MAX_VERTICES;
    var order = [_]i32{0} ** MAX_VERTICES;
    var stack = [_]i32{0} ** MAX_VERTICES;
    parent[0] = -1;
    var top: usize = 1;
    var order_count: usize = 0;
    stack[0] = 0;
    while (top > 0) {
        top -= 1;
        const vertex: usize = @intCast(stack[top]);
        order[order_count] = @intCast(vertex);
        order_count += 1;
        var i = degree[vertex];
        while (i > 0) {
            i -= 1;
            const child: usize = @intCast(adjacency[vertex * MAX_VERTICES + i]);
            if (parent[child] == -2) {
                parent[child] = @intCast(vertex);
                stack[top] = @intCast(child);
                top += 1;
            }
        }
    }
    if (order_count != n) return -1;

    var subtree_size = [_]usize{0} ** MAX_VERTICES;
    var big_child = [_]i32{-1} ** MAX_VERTICES;
    var index = n;
    while (index > 0) {
        index -= 1;
        const vertex: usize = @intCast(order[index]);
        var best_size: usize = 0;
        subtree_size[vertex] = 1;
        for (0..degree[vertex]) |neighbor_index| {
            const child: usize = @intCast(adjacency[vertex * MAX_VERTICES + neighbor_index]);
            if (parent[child] != @as(i32, @intCast(vertex))) continue;
            subtree_size[vertex] += subtree_size[child];
            if (subtree_size[child] > best_size) {
                best_size = subtree_size[child];
                big_child[vertex] = @intCast(child);
            }
        }
    }

    var position = [_]usize{0} ** MAX_VERTICES;
    var head = [_]i32{0} ** MAX_VERTICES;
    var stack_head = [_]i32{0} ** MAX_VERTICES;
    top = 1;
    var next_position: usize = 0;
    stack[0] = 0;
    stack_head[0] = 0;
    while (top > 0) {
        top -= 1;
        const vertex: usize = @intCast(stack[top]);
        const chain_head = stack_head[top];
        position[vertex] = next_position;
        next_position += 1;
        head[vertex] = chain_head;
        var i = degree[vertex];
        while (i > 0) {
            i -= 1;
            const child: usize = @intCast(adjacency[vertex * MAX_VERTICES + i]);
            if (parent[child] == @as(i32, @intCast(vertex)) and @as(i32, @intCast(child)) != big_child[vertex]) {
                stack[top] = @intCast(child);
                stack_head[top] = @intCast(child);
                top += 1;
            }
        }
        if (big_child[vertex] >= 0) {
            stack[top] = big_child[vertex];
            stack_head[top] = chain_head;
            top += 1;
        }
    }

    const required = (1 + 3 * n) * 8;
    if (output == null or capacity < required) return -2;
    putI64(output, 0, nv);
    var cursor: usize = 1;
    for (0..n) |vertex| {
        putI64(output, cursor * 8, @intCast(position[vertex]));
        cursor += 1;
        putI64(output, cursor * 8, head[vertex]);
        cursor += 1;
        putI64(output, cursor * 8, big_child[vertex]);
        cursor += 1;
    }
    return @intCast(required);
}
