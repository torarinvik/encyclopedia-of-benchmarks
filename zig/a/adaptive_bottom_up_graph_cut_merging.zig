const MAX_N: usize = 8;
const MAX_M: usize = 16;
const MAX_B: usize = 4;
const STRIDE: usize = 10;

fn allowedArc(u: usize, v: usize, n: usize, allowed: [MAX_N]bool) bool {
    if (u < n and !allowed[u]) return false;
    if (v < n and !allowed[v]) return false;
    return v != n and u != n + 1;
}

fn augment(residual: *[STRIDE * STRIDE]i64, n: usize, allowed: [MAX_N]bool) void {
    const source = n;
    const sink = n + 1;
    while (true) {
        var parent: [STRIDE]i32 = @splat(-1);
        var queue: [STRIDE]usize = undefined;
        parent[source] = @intCast(source);
        var head: usize = 0;
        var tail: usize = 1;
        queue[0] = source;
        while (head < tail and parent[sink] < 0) {
            const u = queue[head];
            head += 1;
            for (0..n + 2) |v| {
                if (parent[v] < 0 and residual.*[u * STRIDE + v] > 0 and allowedArc(u, v, n, allowed)) {
                    parent[v] = @intCast(u);
                    queue[tail] = v;
                    tail += 1;
                    if (v == sink) break;
                }
            }
        }
        if (parent[sink] < 0) return;
        var amount: i64 = @intCast(n * 7);
        var v = sink;
        while (v != source) {
            const u: usize = @intCast(parent[v]);
            amount = @min(amount, residual.*[u * STRIDE + v]);
            v = u;
        }
        v = sink;
        while (v != source) {
            const u: usize = @intCast(parent[v]);
            residual.*[u * STRIDE + v] -= amount;
            residual.*[v * STRIDE + u] += amount;
            v = u;
        }
    }
}

pub export fn adaptive_bottom_up_graph_cut_merging(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 3 or length > 92) return -1;
    const rn = input[0];
    const rm = input[1];
    const rb = input[2];
    if (rn < 2 or rn > MAX_N or rm < 0 or rm > MAX_M or rb < 1 or rb > MAX_B or rb > rn or
        length != @as(usize, @intCast(3 + 3 * rn + 4 * rm))) return -1;
    const n: usize = @intCast(rn);
    const m: usize = @intCast(rm);
    const bcount: usize = @intCast(rb);
    var block: [MAX_N]usize = @splat(0);
    var seen: [MAX_B]bool = @splat(false);
    var source_cap: [MAX_N]i64 = @splat(0);
    var sink_cap: [MAX_N]i64 = @splat(0);
    var at: usize = 3;
    for (0..n) |u| {
        const raw = input[at];
        at += 1;
        if (raw < 0 or raw >= rb) return -1;
        block[u] = @intCast(raw);
        seen[block[u]] = true;
    }
    for (0..bcount) |b| if (!seen[b]) return -1;
    for (0..n) |u| {
        source_cap[u] = input[at]; at += 1;
        if (source_cap[u] < 0 or source_cap[u] > 7) return -1;
    }
    for (0..n) |u| {
        sink_cap[u] = input[at]; at += 1;
        if (sink_cap[u] < 0 or sink_cap[u] > 7) return -1;
    }

    var eu: [MAX_M]usize = @splat(0);
    var ev: [MAX_M]usize = @splat(0);
    var ba: [MAX_M]usize = @splat(0);
    var bb: [MAX_M]usize = @splat(0);
    var uv: [MAX_M]i64 = @splat(0);
    var vu: [MAX_M]i64 = @splat(0);
    var cross: [MAX_M]bool = @splat(false);
    var enabled: [MAX_M]bool = @splat(false);
    var residual: [STRIDE * STRIDE]i64 = @splat(0);
    for (0..n) |u| {
        residual[n * STRIDE + u] += source_cap[u];
        residual[u * STRIDE + n + 1] += sink_cap[u];
    }
    var potential: [MAX_B * MAX_B]i64 = @splat(0);
    var present: [MAX_B * MAX_B]bool = @splat(false);
    for (0..m) |i| {
        const ru = input[at];
        const rv = input[at + 1];
        const c = input[at + 2];
        const d = input[at + 3];
        at += 4;
        if (ru < 0 or ru >= rn or rv < 0 or rv >= rn or ru == rv or c < 0 or c > 7 or d < 0 or d > 7) return -1;
        const u: usize = @intCast(ru);
        const v: usize = @intCast(rv);
        eu[i] = u; ev[i] = v; uv[i] = c; vu[i] = d;
        if (block[u] == block[v]) {
            residual[u * STRIDE + v] += c;
            residual[v * STRIDE + u] += d;
        } else {
            ba[i] = @min(block[u], block[v]);
            bb[i] = @max(block[u], block[v]);
            cross[i] = c != 0 or d != 0;
            if (cross[i]) present[ba[i] * MAX_B + bb[i]] = true;
        }
    }
    var allowed: [MAX_N]bool = @splat(false);
    for (0..bcount) |b| {
        for (0..n) |u| allowed[u] = block[u] == b;
        augment(&residual, n, allowed);
    }
    var tag: [MAX_N]u8 = @splat(0);
    for (0..bcount) |b| {
        for (0..n) |u| allowed[u] = block[u] == b;
        var from_source: [STRIDE]bool = @splat(false);
        var to_sink: [STRIDE]bool = @splat(false);
        var queue: [STRIDE]usize = undefined;
        var head: usize = 0;
        var tail: usize = 1;
        from_source[n] = true; queue[0] = n;
        while (head < tail) {
            const u = queue[head]; head += 1;
            for (0..n + 2) |v| {
                if (!from_source[v] and residual[u * STRIDE + v] > 0 and (u >= n or allowed[u]) and (v >= n or allowed[v])) {
                    from_source[v] = true; queue[tail] = v; tail += 1;
                }
            }
        }
        head = 0; tail = 1;
        to_sink[n + 1] = true; queue[0] = n + 1;
        while (head < tail) {
            const v = queue[head]; head += 1;
            for (0..n + 2) |u| {
                if (!to_sink[u] and residual[u * STRIDE + v] > 0 and (u >= n or allowed[u]) and (v >= n or allowed[v])) {
                    to_sink[u] = true; queue[tail] = u; tail += 1;
                }
            }
        }
        for (0..n) |u| if (allowed[u]) { tag[u] = if (from_source[u]) 1 else if (to_sink[u]) 2 else 0; };
    }
    for (0..m) |i| {
        if (cross[i] and tag[eu[i]] != tag[ev[i]]) {
            potential[ba[i] * MAX_B + bb[i]] += @as(i64, @intFromBool(uv[i] > 0)) + @as(i64, @intFromBool(vu[i] > 0));
        }
    }
    var order_a: [MAX_B * MAX_B]usize = @splat(0);
    var order_b: [MAX_B * MAX_B]usize = @splat(0);
    var order_n: usize = 0;
    for (0..bcount) |a| {
        for (a + 1..bcount) |b| {
            if (!present[a * MAX_B + b]) continue;
            var p = order_n; order_n += 1;
            while (p > 0) {
                const pa = order_a[p - 1]; const pb = order_b[p - 1];
                const prior = potential[pa * MAX_B + pb];
                const current = potential[a * MAX_B + b];
                if (prior > current or (prior == current and (pa < a or (pa == a and pb <= b)))) break;
                order_a[p] = pa; order_b[p] = pb; p -= 1;
            }
            order_a[p] = a; order_b[p] = b;
        }
    }
    var parent: [MAX_B]usize = .{ 0, 1, 2, 3 };
    for (0..order_n) |oi| {
        var a = order_a[oi]; var b = order_b[oi];
        while (parent[a] != a) a = parent[a];
        while (parent[b] != b) b = parent[b];
        if (a == b) continue;
        const root = @min(a, b); const other = @max(a, b); parent[other] = root;
        for (0..m) |i| {
            if (!cross[i] or enabled[i]) continue;
            var x = ba[i]; var y = bb[i];
            while (parent[x] != x) x = parent[x];
            while (parent[y] != y) y = parent[y];
            if (x == y) {
                residual[eu[i] * STRIDE + ev[i]] += uv[i];
                residual[ev[i] * STRIDE + eu[i]] += vu[i];
                enabled[i] = true;
            }
        }
        for (0..n) |u| {
            var x = block[u];
            while (parent[x] != x) x = parent[x];
            allowed[u] = x == root;
        }
        augment(&residual, n, allowed);
    }
    var flow: i64 = 0;
    for (0..n) |u| flow += source_cap[u] - residual[n * STRIDE + u];
    return flow;
}
