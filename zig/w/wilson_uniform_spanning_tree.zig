const MAX_N: usize = 8;
const MAX_EDGES: usize = 28;
const WALK_LIMIT: usize = 64;
const MAX_INPUT: usize = 4 + 2 * MAX_EDGES + WALK_LIMIT * (MAX_N - 1);

fn writeI64Le(output: [*c]u8, offset: usize, value: i64) void {
    const bytes = @as(u64, @bitCast(value));
    for (0..8) |byte| output[offset + byte] = @truncate(bytes >> @intCast(8 * byte));
}

pub export fn wilson_uniform_spanning_tree(input: [*c]const i64, length: usize,
        output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 4 or length > MAX_INPUT + 1) return -1;
    const n_raw = input[0];
    const m_raw = input[1];
    const root_raw = input[2];
    if (n_raw < 1 or n_raw > MAX_N or m_raw < 0 or m_raw > MAX_EDGES) return -1;
    const n: usize = @intCast(n_raw);
    const m: usize = @intCast(m_raw);
    if (root_raw < 0 or root_raw >= n_raw) return -1;
    const root: usize = @intCast(root_raw);
    const q_at = 3 + 2 * m;
    if (length <= q_at) return -1;
    const q_raw = input[q_at];
    if (q_raw < 0 or q_raw > @as(i64, @intCast(WALK_LIMIT * (n - 1)))) return -1;
    const q: usize = @intCast(q_raw);
    if (length != q_at + 1 + q) return -1;

    var neighbors: [MAX_N][MAX_N - 1]usize = @splat(@splat(0));
    var degree: [MAX_N]usize = @splat(0);
    var previous_u: i64 = -1;
    var previous_v: i64 = -1;
    for (0..m) |edge| {
        const u_raw = input[3 + 2 * edge];
        const v_raw = input[4 + 2 * edge];
        if (u_raw < 0 or u_raw >= v_raw or v_raw >= n_raw) return -1;
        if (edge > 0 and (u_raw < previous_u or (u_raw == previous_u and v_raw <= previous_v))) return -1;
        previous_u = u_raw;
        previous_v = v_raw;
        const u: usize = @intCast(u_raw);
        const v: usize = @intCast(v_raw);
        neighbors[u][degree[u]] = v;
        degree[u] += 1;
        neighbors[v][degree[v]] = u;
        degree[v] += 1;
    }
    for (0..q) |draw| {
        if (input[q_at + 1 + draw] < 0 or input[q_at + 1 + draw] > MAX_N - 2) return -1;
    }

    var seen: [MAX_N]bool = @splat(false);
    var queue: [MAX_N]usize = @splat(0);
    var head: usize = 0;
    var tail: usize = 0;
    seen[root] = true;
    queue[tail] = root;
    tail += 1;
    while (head < tail) {
        const at = queue[head];
        head += 1;
        for (0..degree[at]) |k| {
            const to = neighbors[at][k];
            if (!seen[to]) {
                seen[to] = true;
                queue[tail] = to;
                tail += 1;
            }
        }
    }
    for (0..n) |vertex| {
        if (!seen[vertex]) return -1;
    }

    var in_tree: [MAX_N]bool = @splat(false);
    var successor: [MAX_N]i64 = @splat(-1);
    in_tree[root] = true;
    var cursor: usize = 0;
    for (0..n) |start| {
        if (in_tree[start]) continue;
        var current = start;
        var steps: usize = 0;
        while (!in_tree[current]) {
            if (steps >= WALK_LIMIT or cursor >= q) return -1;
            const choice: usize = @intCast(input[q_at + 1 + cursor]);
            if (choice >= degree[current]) return -1;
            successor[current] = @intCast(neighbors[current][choice]);
            current = @intCast(successor[current]);
            cursor += 1;
            steps += 1;
        }
        current = start;
        while (!in_tree[current]) {
            in_tree[current] = true;
            current = @intCast(successor[current]);
        }
    }
    if (cursor != q) return -1;

    const required = 16 * (n - 1);
    if ((required > 0 and output == null) or capacity < required) return -2;
    var offset: usize = 0;
    for (0..n) |child| {
        if (child == root) continue;
        writeI64Le(output, offset, @intCast(child));
        offset += 8;
        writeI64Le(output, offset, successor[child]);
        offset += 8;
    }
    return @intCast(required);
}
