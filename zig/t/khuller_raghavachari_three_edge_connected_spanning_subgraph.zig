const MAX_N: usize = 8;
const MAX_M: usize = 28;
const MAX_INPUT: usize = 59;

fn put(out: [*]u8, at: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| out[at + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn khuller_raghavachari_three_edge_connected_spanning_subgraph(
    input_opt: ?[*]const i64, length: usize, output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > MAX_INPUT) return -1;
    const input = input_opt.?;
    const n64 = input[0];
    const m64 = input[1];
    if (n64 < 4 or n64 > 8 or m64 < 6 or m64 > 28
        or length != 2 + 2 * @as(usize, @intCast(m64))) return -1;
    const n: usize = @intCast(n64);
    const m: usize = @intCast(m64);
    var u: [MAX_M]usize = @splat(0);
    var v: [MAX_M]usize = @splat(0);
    for (0..m) |edge| {
        const a = input[2 + 2 * edge];
        const b = input[3 + 2 * edge];
        if (a < 0 or a >= b or b >= n64) return -1;
        u[edge] = @intCast(a);
        v[edge] = @intCast(b);
        for (0..edge) |prior| {
            if (u[prior] == u[edge] and v[prior] == v[edge]) return -1;
        }
    }
    const full = (@as(usize, 1) << n) - 1;
    for (1..full) |side| {
        if ((side & 1) == 0) continue;
        var cut: usize = 0;
        for (0..m) |edge| {
            if (((side >> u[edge]) & 1) != ((side >> v[edge]) & 1)) cut += 1;
        }
        if (cut < 3) return -1;
    }

    var selected: [MAX_M]bool = @splat(false);
    var state: [MAX_N]usize = @splat(0);
    var discovery: [MAX_N]usize = @splat(0);
    var finish: [MAX_N]usize = @splat(0);
    var parent: [MAX_N]usize = @splat(0);
    var parent_edge: [MAX_N]usize = @splat(0);
    var postorder: [MAX_N]usize = @splat(0);
    var stack_vertex: [MAX_N]usize = @splat(0);
    var stack_slot: [MAX_N]usize = @splat(0);
    var post_count: usize = 0;
    var clock: usize = 1;
    var top: usize = 1;
    state[0] = 1; discovery[0] = 0; parent[0] = n; parent_edge[0] = m;
    stack_vertex[0] = 0;
    while (top > 0) {
        const frame = top - 1;
        const x = stack_vertex[frame];
        if (stack_slot[frame] < m) {
            const edge = stack_slot[frame];
            stack_slot[frame] += 1;
            const y = if (u[edge] == x) v[edge] else if (v[edge] == x) u[edge] else n;
            if (y == n or state[y] != 0) continue;
            selected[edge] = true; state[y] = 1; parent[y] = x; parent_edge[y] = edge;
            discovery[y] = clock; clock += 1;
            stack_vertex[top] = y; stack_slot[top] = 0; top += 1;
            continue;
        }
        state[x] = 2; finish[x] = clock;
        if (parent_edge[x] < m) { postorder[post_count] = parent_edge[x]; post_count += 1; }
        top -= 1;
    }

    for (0..post_count) |position| {
        const tree_edge = postorder[position];
        const child = if (parent_edge[u[tree_edge]] == tree_edge) u[tree_edge] else v[tree_edge];
        const upper = parent[child];
        var separated = false;
        for (0..m) |removed| {
            if (separated or !selected[removed]) continue;
            var seen: [MAX_N]bool = @splat(false);
            var queue: [MAX_N]usize = @splat(0);
            var head: usize = 0;
            var tail: usize = 1;
            seen[upper] = true; queue[0] = upper;
            while (head < tail) {
                const current = queue[head]; head += 1;
                for (0..m) |edge| {
                    if (!selected[edge] or edge == removed) continue;
                    const next = if (u[edge] == current) v[edge]
                        else if (v[edge] == current) u[edge] else n;
                    if (next < n and !seen[next]) { seen[next] = true; queue[tail] = next; tail += 1; }
                }
            }
            separated = !seen[child];
        }
        if (!separated) continue;
        var candidate: usize = m;
        var earliest: usize = n;
        for (0..m) |edge| {
            if (selected[edge]) continue;
            const u_inside = discovery[child] <= discovery[u[edge]] and discovery[u[edge]] < finish[child];
            const v_inside = discovery[child] <= discovery[v[edge]] and discovery[v[edge]] < finish[child];
            if (u_inside == v_inside) continue;
            const ancestor = if (u_inside) v[edge] else u[edge];
            if (discovery[ancestor] < earliest) { earliest = discovery[ancestor]; candidate = edge; }
        }
        if (candidate == m) return -1;
        selected[candidate] = true;
    }

    var leader: [MAX_N]usize = @splat(0);
    for (0..n) |vertex| leader[vertex] = vertex;
    for (0..m) |edge| {
        if (selected[edge]) continue;
        var a = u[edge];
        var b = v[edge];
        while (leader[a] != a) { leader[a] = leader[leader[a]]; a = leader[a]; }
        while (leader[b] != b) { leader[b] = leader[leader[b]]; b = leader[b]; }
        if (a != b) { leader[b] = a; selected[edge] = true; }
    }
    var count: usize = 0;
    for (0..m) |edge| { if (selected[edge]) count += 1; }
    const bytes = 8 * (1 + 2 * count);
    if (output_opt == null or capacity < bytes) return -2;
    const output = output_opt.?;
    put(output, 0, @intCast(count));
    var slot: usize = 0;
    for (0..m) |edge| {
        if (!selected[edge]) continue;
        put(output, 8 * (1 + 2 * slot), @intCast(u[edge]));
        put(output, 8 * (2 + 2 * slot), @intCast(v[edge]));
        slot += 1;
    }
    return @intCast(bytes);
}
