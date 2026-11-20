const MAX_N: usize = 8;
const MAX_M: usize = 28;
const MAX_INPUT: usize = 59;
const MAX_STATES: usize = 1 << MAX_N;

fn put(out: [*]u8, at: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| out[at + byte] = @truncate(bits >> @intCast(8 * byte));
}

fn biconnected(n: usize, m: usize, u: *const [MAX_M]usize,
               v: *const [MAX_M]usize, active: *const [MAX_M]bool) bool {
    for (0..n) |removed| {
        const start: usize = if (removed == 0) 1 else 0;
        var seen: [MAX_N]bool = @splat(false);
        var queue: [MAX_N]usize = @splat(0);
        var head: usize = 0;
        var tail: usize = 1;
        seen[start] = true;
        queue[0] = start;
        while (head < tail) {
            const current = queue[head];
            head += 1;
            for (0..m) |edge| {
                if (!active[edge] or u[edge] == removed or v[edge] == removed) continue;
                const next = if (u[edge] == current) v[edge]
                    else if (v[edge] == current) u[edge] else n;
                if (next < n and !seen[next]) {
                    seen[next] = true;
                    queue[tail] = next;
                    tail += 1;
                }
            }
        }
        for (0..n) |vertex| {
            if (vertex != removed and !seen[vertex]) return false;
        }
    }
    return true;
}

export fn cheriyan_thurimella_two_vertex_connected_augmentation(
    input_opt: ?[*]const i64, length: usize, output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > MAX_INPUT) return -1;
    const input = input_opt.?;
    const n64 = input[0];
    const m64 = input[1];
    if (n64 < 3 or n64 > 8 or m64 < 3 or m64 > 28
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
    var active: [MAX_M]bool = @splat(false);
    for (0..m) |edge| active[edge] = true;
    if (!biconnected(n, m, &u, &v, &active)) return -1;

    const states: usize = 1 << n;
    var best: [MAX_STATES]i32 = @splat(0);
    var choice: [MAX_STATES]i32 = @splat(-1);
    for (1..states) |mask| {
        const first: usize = @intCast(@ctz(mask));
        for (0..m) |edge| {
            const other = if (u[edge] == first) v[edge]
                else if (v[edge] == first) u[edge] else n;
            if (other == n or mask & (@as(usize, 1) << @intCast(other)) == 0) continue;
            const rest = mask & ~(@as(usize, 1) << @intCast(first))
                & ~(@as(usize, 1) << @intCast(other));
            const candidate = 1 + best[rest];
            if (candidate > best[mask]) {
                best[mask] = candidate;
                choice[mask] = @intCast(edge);
            }
        }
        const rest = mask & ~(@as(usize, 1) << @intCast(first));
        if (best[rest] > best[mask]) {
            best[mask] = best[rest];
            choice[mask] = -1;
        }
    }
    var cover: [MAX_M]bool = @splat(false);
    var covered: [MAX_N]bool = @splat(false);
    var mask = states - 1;
    while (mask != 0) {
        const first: usize = @intCast(@ctz(mask));
        const edge = choice[mask];
        if (edge < 0) { mask &= ~(@as(usize, 1) << @intCast(first)); continue; }
        const e: usize = @intCast(edge);
        cover[e] = true;
        covered[u[e]] = true;
        covered[v[e]] = true;
        mask &= ~(@as(usize, 1) << u[e]) & ~(@as(usize, 1) << v[e]);
    }
    for (0..n) |vertex| {
        if (covered[vertex]) continue;
        for (0..m) |edge| {
            if (u[edge] == vertex or v[edge] == vertex) {
                cover[edge] = true;
                covered[u[edge]] = true;
                covered[v[edge]] = true;
                break;
            }
        }
    }
    for (0..m) |edge| {
        if (cover[edge]) continue;
        active[edge] = false;
        if (!biconnected(n, m, &u, &v, &active)) active[edge] = true;
    }
    var count: usize = 0;
    for (0..m) |edge| {
        if (active[edge]) count += 1;
    }
    const bytes = 8 * (1 + 2 * count);
    if (output_opt == null or capacity < bytes) return -2;
    const output = output_opt.?;
    put(output, 0, @intCast(count));
    var slot: usize = 0;
    for (0..m) |edge| {
        if (!active[edge]) continue;
        put(output, 8 * (1 + 2 * slot), @intCast(u[edge]));
        put(output, 8 * (2 + 2 * slot), @intCast(v[edge]));
        slot += 1;
    }
    return @intCast(bytes);
}
