/// Minimum walk length covering all vertices via multi-source product BFS.
const MAX_N: usize = 10;
const MAX_STATES: usize = 10240;

export fn shortest_path_visiting_all_nodes(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 2 or length > 93) return -1;
    const input = input_opt.?;
    const n_value = input[0];
    const m_value = input[1];
    if (n_value < 1 or n_value > MAX_N or m_value < 0 or m_value > 45) return -1;
    const n: usize = @intCast(n_value);
    const m: usize = @intCast(m_value);
    if (m > n * (n - 1) / 2 or length != 2 + 2 * m) return -1;

    var adjacency: [MAX_N]u16 = @splat(0);
    for (0..m) |edge| {
        const u_value = input[2 + 2 * edge];
        const v_value = input[3 + 2 * edge];
        if (u_value < 0 or v_value < 0 or u_value >= n_value or v_value >= n_value or u_value == v_value) return -1;
        const u: usize = @intCast(u_value);
        const v: usize = @intCast(v_value);
        const u_bit: u16 = @as(u16, 1) << @intCast(v);
        const v_bit: u16 = @as(u16, 1) << @intCast(u);
        if ((adjacency[u] & u_bit) != 0) return -1;
        adjacency[u] |= u_bit;
        adjacency[v] |= v_bit;
    }

    var reached: u16 = 1;
    while (true) {
        const previous = reached;
        for (0..n) |vertex| {
            if ((reached & (@as(u16, 1) << @intCast(vertex))) != 0) reached |= adjacency[vertex];
        }
        if (reached == previous) break;
    }
    const full: u16 = (@as(u16, 1) << @intCast(n)) - 1;
    if (reached != full) return -1;

    var distance: [MAX_STATES]i16 = @splat(-1);
    var queue: [MAX_STATES]u16 = @splat(0);
    var head: usize = 0;
    var tail: usize = 0;
    for (0..n) |start| {
        const state = (@as(usize, 1) << @intCast(start)) * n + start;
        distance[state] = 0;
        queue[tail] = @intCast(state);
        tail += 1;
    }
    while (head < tail) {
        const state: usize = @intCast(queue[head]);
        head += 1;
        const mask = state / n;
        const vertex = state % n;
        if (mask == @as(usize, @intCast(full))) return distance[state];
        for (0..n) |next| {
            if ((adjacency[vertex] & (@as(u16, 1) << @intCast(next))) == 0) continue;
            const next_mask = mask | (@as(usize, 1) << @intCast(next));
            const next_state = next_mask * n + next;
            if (distance[next_state] >= 0) continue;
            distance[next_state] = distance[state] + 1;
            queue[tail] = @intCast(next_state);
            tail += 1;
        }
    }
    return -1;
}
