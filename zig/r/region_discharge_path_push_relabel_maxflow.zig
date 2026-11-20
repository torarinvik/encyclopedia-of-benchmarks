const NMAX: usize = 8;
const MMAX: usize = 12;
const KMAX: usize = 4;
const INPUT_MAX: usize = 50;

fn reaches(n: usize, allowed: [NMAX * NMAX]bool, residual: [NMAX * NMAX]i64,
           start: usize, target: [NMAX]bool) bool {
    if (target[start]) return true;
    var seen: [NMAX]bool = @splat(false);
    var queue: [NMAX]usize = undefined;
    var head: usize = 0;
    var tail: usize = 1;
    seen[start] = true;
    queue[0] = start;
    while (head < tail) {
        const u = queue[head]; head += 1;
        for (0..n) |v| {
            if (!seen[v] and allowed[u * NMAX + v] and residual[u * NMAX + v] > 0) {
                if (target[v]) return true;
                seen[v] = true; queue[tail] = v; tail += 1;
            }
        }
    }
    return false;
}

fn findPath(n: usize, in_region: [NMAX]bool, allowed: [NMAX * NMAX]bool,
            residual: [NMAX * NMAX]i64, target: [NMAX]bool,
            excess: [NMAX]i64, parent: *[NMAX]isize) isize {
    parent.* = @splat(-1);
    var queue: [NMAX]usize = undefined;
    var head: usize = 0;
    var tail: usize = 0;
    for (0..n) |v| {
        if (in_region[v] and excess[v] > 0) {
            parent.*[v] = @intCast(v); queue[tail] = v; tail += 1;
        }
    }
    while (head < tail) {
        const u = queue[head]; head += 1;
        for (0..n) |v| {
            if (parent.*[v] >= 0 or !allowed[u * NMAX + v] or residual[u * NMAX + v] <= 0) continue;
            parent.*[v] = @intCast(u);
            if (target[v]) return @intCast(v);
            queue[tail] = v; tail += 1;
        }
    }
    return -1;
}

fn discharge(n: usize, region_id: usize, source: usize, sink: usize,
             boundary_count: usize, regions: [NMAX]i64,
             boundary_by_region: [KMAX * NMAX]bool,
             residual: *[NMAX * NMAX]i64, excess: *[NMAX]i64,
             labels: *[NMAX]usize, flow_value: i64) i64 {
    var in_region: [NMAX]bool = @splat(false);
    var external: [NMAX]bool = @splat(false);
    var inside_terminal: [NMAX]bool = @splat(false);
    var allowed: [NMAX * NMAX]bool = @splat(false);
    var local: [NMAX * NMAX]i64 = @splat(0);
    for (0..n) |v| {
        in_region[v] = v != source and v != sink and regions[v] == @as(i64, @intCast(region_id));
        external[v] = boundary_by_region[region_id * NMAX + v];
        inside_terminal[v] = in_region[v] or v == source or v == sink;
    }
    for (0..n) |u| for (0..n) |v| {
        allowed[u * NMAX + v] = (inside_terminal[u] and inside_terminal[v]) or
            (in_region[u] and external[v]) or (external[u] and in_region[v]);
        if (allowed[u * NMAX + v] and !(external[u] and in_region[v]))
            local[u * NMAX + v] = residual.*[u * NMAX + v];
    };
    var flow = flow_value;
    for (0..boundary_count + 1) |stage| {
        var target: [NMAX]bool = @splat(false);
        target[sink] = true;
        for (0..n) |v| if (external[v] and labels.*[v] < stage) { target[v] = true; };
        while (true) {
            var parent: [NMAX]isize = @splat(-1);
            const finish_raw = findPath(n, in_region, allowed, local, target, excess.*, &parent);
            if (finish_raw < 0) break;
            const finish: usize = @intCast(finish_raw);
            var path: [NMAX]usize = undefined;
            var path_len: usize = 0;
            var v = finish;
            while (true) {
                path[path_len] = v; path_len += 1;
                if (parent[v] == @as(isize, @intCast(v))) break;
                v = @intCast(parent[v]);
            }
            const start = path[path_len - 1];
            var amount = excess.*[start];
            var i = path_len - 1;
            while (i > 0) : (i -= 1) {
                const u = path[i]; const w = path[i - 1];
                amount = @min(amount, local[u * NMAX + w]);
            }
            i = path_len - 1;
            while (i > 0) : (i -= 1) {
                const u = path[i]; const w = path[i - 1];
                local[u * NMAX + w] -= amount; local[w * NMAX + u] += amount;
                residual.*[u * NMAX + w] -= amount; residual.*[w * NMAX + u] += amount;
            }
            excess.*[start] -= amount;
            if (finish == sink) flow += amount else excess.*[finish] += amount;
        }
    }
    for (0..n) |u| {
        if (in_region[u]) {
            var next_label = boundary_count;
            for (0..boundary_count + 1) |stage| {
                var target: [NMAX]bool = @splat(false);
                target[sink] = true;
                for (0..n) |v| if (external[v] and labels.*[v] < stage) { target[v] = true; };
                if (reaches(n, allowed, local, u, target)) { next_label = stage; break; }
            }
            if (next_label > labels.*[u]) labels.*[u] = next_label;
        }
    }
    return flow;
}

pub export fn region_discharge_path_push_relabel_maxflow(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 5 or length > INPUT_MAX) return -1;
    const rn = input[0]; const rm = input[1]; const rk = input[2];
    const rs = input[3]; const rt = input[4];
    if (rn < 4 or rn > NMAX or rm < 1 or rm > MMAX or rk < 2 or rk > KMAX or rk > rn - 2 or
        rs < 0 or rs >= rn or rt < 0 or rt >= rn or rs == rt or
        length != 5 + @as(usize, @intCast(rn)) + 3 * @as(usize, @intCast(rm))) return -1;
    const n: usize = @intCast(rn); const m: usize = @intCast(rm); const k: usize = @intCast(rk);
    const source: usize = @intCast(rs); const sink: usize = @intCast(rt);
    var regions: [NMAX]i64 = @splat(0);
    var seen: [KMAX]bool = @splat(false);
    var capacity: [NMAX * NMAX]i64 = @splat(0);
    var residual: [NMAX * NMAX]i64 = @splat(0);
    var boundary_by_region: [KMAX * NMAX]bool = @splat(false);
    var boundary: [NMAX]bool = @splat(false);
    var excess: [NMAX]i64 = @splat(0);
    var labels: [NMAX]usize = @splat(0);
    for (0..n) |v| {
        const raw = input[5 + v];
        if (v == source or v == sink) { if (raw != -1) return -1; regions[v] = -1; }
        else { if (raw < 0 or raw >= rk) return -1; regions[v] = raw; seen[@intCast(raw)] = true; }
    }
    for (0..k) |b| if (!seen[b]) return -1;
    for (0..m) |e| {
        const p = 5 + n + 3 * e;
        const ru = input[p]; const rv = input[p + 1]; const cap = input[p + 2];
        if (ru < 0 or ru >= rn or rv < 0 or rv >= rn or ru == rv or rv == rs or ru == rt or cap < 0 or cap > 7) return -1;
        const u: usize = @intCast(ru); const v: usize = @intCast(rv);
        capacity[u * NMAX + v] += cap;
        if (cap > 0 and regions[u] >= 0 and regions[v] >= 0 and regions[u] != regions[v]) {
            boundary[u] = true; boundary[v] = true;
            boundary_by_region[@as(usize, @intCast(regions[u])) * NMAX + v] = true;
            boundary_by_region[@as(usize, @intCast(regions[v])) * NMAX + u] = true;
        }
    }
    var boundary_count: usize = 0;
    for (0..n) |v| { if (boundary[v]) boundary_count += 1; }
    if (boundary_count < 2) return -1;
    residual = capacity;
    var flow: i64 = 0;
    for (0..n) |v| {
        const amount = residual[source * NMAX + v];
        if (amount > 0) {
            residual[source * NMAX + v] = 0;
            residual[v * NMAX + source] += amount;
            if (v == sink) flow += amount else excess[v] += amount;
        }
    }
    labels[source] = boundary_count;
    for (0..2 * boundary_count * boundary_count + 1) |_| {
        for (0..k) |b| flow = discharge(n, b, source, sink, boundary_count, regions,
            boundary_by_region, &residual, &excess, &labels, flow);
        var active = false;
        for (0..n) |v| { if (v != source and v != sink and excess[v] > 0 and labels[v] < boundary_count) active = true; }
        if (!active) return flow;
    }
    return -1;
}
