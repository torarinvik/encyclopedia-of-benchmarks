const MAX_N: usize = 8;
const MAX_M: usize = 28;
const MAX_INPUT: usize = 59;
const INF: usize = 9;

fn put(out: [*]u8, at: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| out[at + byte] = @truncate(bits >> @intCast(8 * byte));
}

fn distances(n: usize, m: usize, u: [MAX_M]usize, v: [MAX_M]usize,
             selected: [MAX_M]bool, only_selected: bool) [MAX_N][MAX_N]usize {
    var d: [MAX_N][MAX_N]usize = @splat(@splat(INF));
    for (0..n) |vertex| d[vertex][vertex] = 0;
    for (0..m) |edge| {
        if (only_selected and !selected[edge]) continue;
        d[u[edge]][v[edge]] = 1; d[v[edge]][u[edge]] = 1;
    }
    for (0..n) |via| for (0..n) |left| for (0..n) |right| {
        const candidate = d[left][via] + d[via][right];
        if (candidate < d[left][right]) d[left][right] = candidate;
    };
    return d;
}

export fn additive_two_spanner_completion(
    input_opt: ?[*]const i64, length: usize, output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > MAX_INPUT) return -1;
    const input = input_opt.?;
    const n64 = input[0]; const m64 = input[1];
    if (n64 < 1 or n64 > 8 or m64 < 0 or m64 > 28
        or length != 2 + 2 * @as(usize, @intCast(m64))) return -1;
    const n: usize = @intCast(n64); const m: usize = @intCast(m64);
    var u: [MAX_M]usize = @splat(0); var v: [MAX_M]usize = @splat(0);
    for (0..m) |edge| {
        const a = input[2 + 2 * edge]; const b = input[3 + 2 * edge];
        if (a < 0 or a >= b or b >= n64) return -1;
        u[edge] = @intCast(a); v[edge] = @intCast(b);
        for (0..edge) |prior| if (u[prior] == u[edge] and v[prior] == v[edge]) return -1;
    }
    var selected: [MAX_M]bool = @splat(false);
    const original = distances(n, m, u, v, selected, false);
    for (0..m + 1) |round| {
        const current = distances(n, m, u, v, selected, true);
        var source = n; var target = n;
        for (0..n) |a| {
            if (source != n) break;
            for (a + 1..n) |b| {
                if (original[a][b] < INF and current[a][b] > original[a][b] + 2) {
                    source = a; target = b; break;
                }
            }
        }
        if (source == n) break;
        if (round == m) return -1;
        var vertex = source;
        while (vertex != target) {
            var next = n;
            for (0..n) |neighbor| {
                if (neighbor == vertex or original[neighbor][target] + 1 != original[vertex][target]) continue;
                for (0..m) |edge| {
                    if ((u[edge] == vertex and v[edge] == neighbor)
                        or (v[edge] == vertex and u[edge] == neighbor)) {
                        next = neighbor; selected[edge] = true; break;
                    }
                }
                if (next != n) break;
            }
            if (next == n) return -1;
            vertex = next;
        }
    }
    var count: usize = 0;
    for (0..m) |edge| if (selected[edge]) { count += 1; };
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
