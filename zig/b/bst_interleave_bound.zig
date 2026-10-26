const MAX_NODES: usize = 8;
const MAX_ACCESSES: usize = 16;
const MAX_INPUT: usize = 36;

fn store_i64_le(output: [*]u8, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn bst_interleave_bound(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 3 or length > MAX_INPUT) return -1;
    const input = input_opt.?;
    const n_raw = input[0];
    const root_raw = input[1];
    if (n_raw < 1 or n_raw > @as(i64, MAX_NODES) or root_raw < 0 or root_raw >= n_raw) return -1;
    const n: usize = @intCast(n_raw);
    const root: usize = @intCast(root_raw);
    var left: [MAX_NODES]i32 = @splat(-1);
    var right: [MAX_NODES]i32 = @splat(-1);
    var parent: [MAX_NODES]i32 = @splat(-1);
    var parent_count: [MAX_NODES]u8 = @splat(0);
    var position: usize = 2;
    for (0..n) |node| {
        if (position + 2 > length) return -1;
        const l = input[position]; position += 1;
        const r = input[position]; position += 1;
        if (l < -1 or l >= n_raw or r < -1 or r >= n_raw or l == @as(i64, @intCast(node))
            or r == @as(i64, @intCast(node)) or (l >= 0 and l == r)) return -1;
        left[node] = @intCast(l);
        right[node] = @intCast(r);
        if (l >= 0) {
            const child: usize = @intCast(l);
            parent_count[child] += 1;
            parent[child] = @intCast(node);
        }
        if (r >= 0) {
            const child: usize = @intCast(r);
            parent_count[child] += 1;
            parent[child] = @intCast(node);
        }
    }
    if (parent_count[root] != 0) return -1;
    for (0..n) |node| if (node != root and parent_count[node] != 1) return -1;
    if (position >= length) return -1;
    const m_raw = input[position]; position += 1;
    if (m_raw < 0 or m_raw > @as(i64, MAX_ACCESSES) or length != position + @as(usize, @intCast(m_raw))) return -1;
    const m: usize = @intCast(m_raw);
    var accesses: [MAX_ACCESSES]usize = @splat(0);
    for (0..m) |i| {
        const key = input[position]; position += 1;
        if (key < 0 or key >= n_raw) return -1;
        accesses[i] = @intCast(key);
    }

    var stack_node: [MAX_NODES]usize = @splat(0);
    var stack_low: [MAX_NODES]i32 = @splat(0);
    var stack_high: [MAX_NODES]i32 = @splat(0);
    var visited: [MAX_NODES]bool = @splat(false);
    var stack_size: usize = 1;
    var visited_count: usize = 0;
    stack_node[0] = root;
    stack_low[0] = -1;
    stack_high[0] = @intCast(n);
    while (stack_size > 0) {
        stack_size -= 1;
        const node = stack_node[stack_size];
        const low = stack_low[stack_size];
        const high = stack_high[stack_size];
        if (visited[node] or @as(i32, @intCast(node)) <= low or @as(i32, @intCast(node)) >= high) return -1;
        visited[node] = true;
        visited_count += 1;
        if (left[node] >= 0) {
            stack_node[stack_size] = @intCast(left[node]);
            stack_low[stack_size] = low;
            stack_high[stack_size] = @intCast(node);
            stack_size += 1;
        }
        if (right[node] >= 0) {
            stack_node[stack_size] = @intCast(right[node]);
            stack_low[stack_size] = @intCast(node);
            stack_high[stack_size] = high;
            stack_size += 1;
        }
    }
    if (visited_count != n) return -1;

    var bound: i64 = 0;
    for (0..n) |pivot| {
        var previous: i32 = -1;
        for (0..m) |i| {
            const key = accesses[i];
            var ancestor: i32 = @intCast(key);
            while (ancestor >= 0 and ancestor != @as(i32, @intCast(pivot))) : (ancestor = parent[@intCast(ancestor)]) {}
            if (ancestor == @as(i32, @intCast(pivot))) {
                const side: i32 = if (key <= pivot) 0 else 1;
                if (previous >= 0 and side != previous) bound += 1;
                previous = side;
            }
        }
    }
    if (output_opt == null or capacity < 8) return -2;
    const output = output_opt.?;
    var staged: [8]u8 = @splat(0);
    store_i64_le(&staged, bound);
    for (0..8) |byte| output[byte] = staged[byte];
    return 8;
}
