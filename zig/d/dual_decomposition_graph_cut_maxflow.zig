const MAX_N: usize = 6;
const MAX_M: usize = 10;
const STRIDE: usize = 8;
const OFFSET: i64 = 7000;
const SCALES: [9]i64 = .{ 0, 2, 2, 6, 12, 60, 60, 420, 840 };

fn member(owner: u8, side: u8) bool { return owner == side or owner == 2; }

fn solve(side: u8, n: usize, m: usize, owner: [MAX_N]u8,
    source_cap: [MAX_N]i64, sink_cap: [MAX_N]i64,
    eu: [MAX_M]usize, ev: [MAX_M]usize, uv: [MAX_M]i64, vu: [MAX_M]i64,
    lambda: [MAX_N]i64, scale: i64, labels: *[MAX_N]i64) i64 {
    const source = n;
    const sink = n + 1;
    const size = n + 2;
    var residual: [STRIDE * STRIDE]i64 = @splat(0);
    var constant: i64 = 0;
    var flow: i64 = 0;
    var source_sum: i64 = 0;
    var lambda_sum: i64 = 0;
    for (0..n) |u| {
        source_sum += source_cap[u];
        if (member(owner[u], side)) {
            const factor = if (owner[u] == 2) scale / 2 else scale;
            residual[source * STRIDE + u] += source_cap[u] * factor;
            residual[u * STRIDE + sink] += sink_cap[u] * factor;
        }
        if (owner[u] == 2) lambda_sum += if (lambda[u] < 0) -lambda[u] else lambda[u];
    }
    for (0..m) |i| {
        if (member(owner[eu[i]], side) and member(owner[ev[i]], side)) {
            const factor = if (owner[eu[i]] == 2 and owner[ev[i]] == 2) scale / 2 else scale;
            residual[eu[i] * STRIDE + ev[i]] += uv[i] * factor;
            residual[ev[i] * STRIDE + eu[i]] += vu[i] * factor;
        }
    }
    for (0..n) |u| {
        if (owner[u] == 2) {
            const q = if (side == 0) lambda[u] else -lambda[u];
            if (q >= 0) residual[source * STRIDE + u] += q else {
                residual[u * STRIDE + sink] += -q;
                constant += q;
            }
        }
    }
    while (true) {
        var parent: [STRIDE]i32 = @splat(-1);
        var queue: [STRIDE]usize = undefined;
        parent[source] = @intCast(source);
        var head: usize = 0;
        var tail: usize = 1;
        queue[0] = source;
        while (head < tail and parent[sink] < 0) {
            const u = queue[head]; head += 1;
            for (0..size) |v| {
                if (parent[v] < 0 and residual[u * STRIDE + v] > 0) {
                    parent[v] = @intCast(u); queue[tail] = v; tail += 1;
                    if (v == sink) break;
                }
            }
        }
        if (parent[sink] < 0) {
            for (0..n) |u| labels.*[u] = if (member(owner[u], side) and parent[u] < 0) 1 else 0;
            return flow + constant;
        }
        var amount = source_sum * scale + lambda_sum + 1;
        var v = sink;
        while (v != source) {
            const u: usize = @intCast(parent[v]);
            amount = @min(amount, residual[u * STRIDE + v]);
            v = u;
        }
        v = sink;
        while (v != source) {
            const u: usize = @intCast(parent[v]);
            residual[u * STRIDE + v] -= amount;
            residual[v * STRIDE + u] += amount;
            v = u;
        }
        flow += amount;
    }
}

pub export fn dual_decomposition_graph_cut_maxflow(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 4 or length > 63) return -1;
    const rn = input[0]; const rm = input[1]; const ro = input[2]; const rt = input[3];
    if (rn < 3 or rn > MAX_N or rm < 0 or rm > MAX_M or ro < 1 or ro > 3 or rt < 1 or rt > 8 or
        length != @as(usize, @intCast(4 + 3 * rn + 4 * rm))) return -1;
    const n: usize = @intCast(rn); const m: usize = @intCast(rm);
    const overlap: usize = @intCast(ro); const rounds: usize = @intCast(rt);
    var owner: [MAX_N]u8 = @splat(0);
    var counts: [3]usize = @splat(0);
    var at: usize = 4;
    for (0..n) |u| {
        const raw = input[at]; at += 1;
        if (raw < 0 or raw > 2) return -1;
        owner[u] = @intCast(raw); counts[owner[u]] += 1;
    }
    if (counts[0] == 0 or counts[1] == 0 or counts[2] != overlap) return -1;
    var source_cap: [MAX_N]i64 = @splat(0); var sink_cap: [MAX_N]i64 = @splat(0);
    for (0..n) |u| {
        source_cap[u] = input[at]; at += 1;
        if (source_cap[u] < 0 or source_cap[u] > 6 or @rem(source_cap[u], 2) != 0) return -1;
    }
    for (0..n) |u| {
        sink_cap[u] = input[at]; at += 1;
        if (sink_cap[u] < 0 or sink_cap[u] > 6 or @rem(sink_cap[u], 2) != 0) return -1;
    }
    var eu: [MAX_M]usize = @splat(0); var ev: [MAX_M]usize = @splat(0);
    var uv: [MAX_M]i64 = @splat(0); var vu: [MAX_M]i64 = @splat(0);
    for (0..m) |i| {
        const ru = input[at]; const rv = input[at + 1]; const c = input[at + 2]; const d = input[at + 3]; at += 4;
        if (ru < 0 or ru >= rn or rv < 0 or rv >= rn or ru == rv or
            (owner[@intCast(ru)] == 0 and owner[@intCast(rv)] == 1) or (owner[@intCast(ru)] == 1 and owner[@intCast(rv)] == 0) or
            c < 0 or c > 6 or @rem(c, 2) != 0 or d < 0 or d > 6 or @rem(d, 2) != 0) return -1;
        eu[i] = @intCast(ru); ev[i] = @intCast(rv); uv[i] = c; vu[i] = d;
    }
    const scale = SCALES[rounds];
    var lambda: [MAX_N]i64 = @splat(0);
    var labels_m: [MAX_N]i64 = @splat(0); var labels_n: [MAX_N]i64 = @splat(0);
    var dual_scaled: i64 = 0; var agreement = false;
    for (1..rounds + 1) |iteration| {
        const energy_m = solve(0,n,m,owner,source_cap,sink_cap,eu,ev,uv,vu,lambda,scale,&labels_m);
        const energy_n = solve(1,n,m,owner,source_cap,sink_cap,eu,ev,uv,vu,lambda,scale,&labels_n);
        dual_scaled = energy_m + energy_n; agreement = true;
        for (0..n) |u| if (owner[u] == 2 and labels_m[u] != labels_n[u]) { agreement = false; };
        if (agreement or iteration == rounds) break;
        const step: i64 = scale / @as(i64, @intCast(iteration));
        for (0..n) |u| if (owner[u] == 2) { lambda[u] += step * (labels_m[u] - labels_n[u]); };
    }
    return 2 * (dual_scaled + OFFSET) + @as(i64, @intFromBool(agreement));
}
