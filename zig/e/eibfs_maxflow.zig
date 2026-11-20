// Clean-room bounded Excesses IBFS maximum flow.
const N_MAX: usize = 8;
const M_MAX: usize = 24;
const INPUT_MAX: usize = 77;
const FREE_TREE: i32 = 0;
const S_TREE: i32 = 1;
const T_TREE: i32 = 2;

const State = struct {
    n: usize,
    source: usize,
    sink: usize,
    forward: bool,
    kind: [8]i32,
    parent: [8]i32,
    original: [64]i64,
    residual: [64]i64,
    balance: [8]i64,
    ds: [8]i64,
    dt: [8]i64,
    ds_max: i64,
    dt_max: i64,
    orphaned: [8]bool,
    events: usize,
};

fn min64(a: i64, b: i64) i64 { return if (a < b) a else b; }

fn root(s: *State, start: usize) i32 {
    var v = start;
    for (0..s.n) |_| {
        if (s.parent[v] < 0) return @intCast(v);
        v = @intCast(s.parent[v]);
    }
    return -1;
}

fn bottleneck(s: *State, start: usize, kind: i32) i64 {
    var v = start;
    var answer: i64 = 2401;
    for (0..s.n) |_| {
        const p_raw = s.parent[v];
        if (p_raw < 0) return answer;
        const p: usize = @intCast(p_raw);
        answer = min64(answer, if (kind == S_TREE) s.residual[p * N_MAX + v] else s.residual[v * N_MAX + p]);
        v = p;
    }
    return 0;
}

fn push(s: *State, u: usize, v: usize, amount: i64) void {
    s.residual[u * N_MAX + v] -= amount;
    s.residual[v * N_MAX + u] += amount;
    if (u != s.source and u != s.sink) s.balance[u] -= amount;
    if (v != s.source and v != s.sink) s.balance[v] += amount;
}

fn mark(s: *State, v: usize, queue: *[512]usize, tail: *usize) void {
    if (!s.orphaned[v]) { s.orphaned[v] = true; queue[tail.*] = v; tail.* += 1; }
}

fn detach(s: *State, v: usize, kind: i32, queue: *[512]usize, tail: *usize) void {
    for (0..s.n) |child| {
        if (s.kind[child] == kind and s.parent[child] == @as(i32, @intCast(v))) {
            s.parent[child] = -1;
            mark(s, child, queue, tail);
        }
    }
}

fn adopt(s: *State, v: usize, kind: i32, queue: *[512]usize, tail: *usize) void {
    const sink_side = kind == T_TREE;
    s.orphaned[v] = false;
    const old = if (sink_side) s.dt[v] else s.ds[v];
    for (0..s.n) |u| {
        const cap = if (sink_side) s.residual[v * N_MAX + u] else s.residual[u * N_MAX + v];
        const here = if (sink_side) s.dt[v] else s.ds[v];
        const label = if (sink_side) s.dt[u] else s.ds[u];
        if (u != v and s.kind[u] == kind and cap > 0 and here == label + 1) {
            s.parent[v] = @intCast(u);
            return;
        }
    }
    const frontier = if (sink_side) s.dt_max else s.ds_max;
    const subtract = if (sink_side) s.forward else !s.forward;
    const limit = frontier - @as(i64, if (subtract) 1 else 0);
    var best: i64 = @intCast(4 * s.n);
    for (0..s.n) |u| {
        const cap = if (sink_side) s.residual[v * N_MAX + u] else s.residual[u * N_MAX + v];
        const label = if (sink_side) s.dt[u] else s.ds[u];
        if (u != v and s.kind[u] == kind and cap > 0 and label <= limit) best = @min(best, label);
    }
    var parent: i32 = -1;
    for (0..s.n) |u| {
        const cap = if (sink_side) s.residual[v * N_MAX + u] else s.residual[u * N_MAX + v];
        const label = if (sink_side) s.dt[u] else s.ds[u];
        if (u != v and s.kind[u] == kind and cap > 0 and label == best) { parent = @intCast(u); break; }
    }
    if (parent >= 0 and best + 1 > old) {
        detach(s, v, kind, queue, tail);
        s.parent[v] = parent;
        if (sink_side) s.dt[v] = best + 1 else s.ds[v] = best + 1;
        return;
    }
    detach(s, v, kind, queue, tail);
    s.parent[v] = -1;
    s.kind[v] = FREE_TREE;
    if (sink_side and s.balance[v] > 0) {
        s.kind[v] = S_TREE;
        s.ds[v] = s.ds_max + @as(i64, if (s.forward) 1 else 0);
    } else if (!sink_side and s.balance[v] < 0) {
        s.kind[v] = T_TREE;
        s.dt[v] = s.dt_max + @as(i64, if (s.forward) 0 else 1);
    }
}

fn repair_orphans(s: *State, kind: i32, queue: *[512]usize, head0: usize, tail: *usize) void {
    var head = head0;
    while (head < tail.*) : (head += 1) {
        const v = queue[head];
        s.orphaned[v] = false;
        if (s.kind[v] == kind) adopt(s, v, kind, queue, tail);
    }
}

fn drain(s: *State, start: usize, kind: i32) void {
    const root_v = root(s, start);
    if (root_v < 0) return;
    var queue: [512]usize = @splat(0);
    var head: usize = 0;
    var tail: usize = 0;
    var x = start;
    while ((if (kind == T_TREE) s.balance[x] > 0 else s.balance[x] < 0) and s.parent[x] >= 0) {
        const p: usize = @intCast(s.parent[x]);
        const cap = if (kind == T_TREE) s.residual[x * N_MAX + p] else s.residual[p * N_MAX + x];
        const need = if (kind == T_TREE) s.balance[x] else -s.balance[x];
        const amount = min64(need, cap);
        if (amount > 0) { if (kind == T_TREE) push(s, x, p, amount) else push(s, p, x, amount); }
        const after = if (kind == T_TREE) s.balance[x] else -s.balance[x];
        const remaining = if (kind == T_TREE) s.residual[x * N_MAX + p] else s.residual[p * N_MAX + x];
        if (remaining == 0 and after >= 0) { s.parent[x] = -1; mark(s, x, &queue, &tail); break; }
        if (after == 0) break;
        x = p;
    }
    const r: usize = @intCast(root_v);
    if (kind == T_TREE and r != s.sink and s.kind[r] == kind and s.balance[r] >= 0) { s.parent[r] = -1; mark(s, r, &queue, &tail); }
    if (kind == S_TREE and r != s.source and s.kind[r] == kind and s.balance[r] <= 0) { s.parent[r] = -1; mark(s, r, &queue, &tail); }
    repair_orphans(s, kind, &queue, head, &tail);
}

fn repair(s: *State) void {
    while (true) {
        var found = false;
        for (0..s.n) |v| { if (s.kind[v] == T_TREE and s.balance[v] > 0) { drain(s, v, T_TREE); found = true; break; } }
        if (found) continue;
        for (0..s.n) |v| { if (s.kind[v] == S_TREE and s.balance[v] < 0) { drain(s, v, S_TREE); found = true; break; } }
        if (!found) return;
    }
}

fn augment(s: *State, v: usize, w: usize) bool {
    const rs0 = root(s, v); const rt0 = root(s, w);
    if (rs0 < 0 or rt0 < 0 or s.residual[v * N_MAX + w] <= 0) return false;
    const rs: usize = @intCast(rs0); const rt: usize = @intCast(rt0);
    const c = s.residual[v * N_MAX + w]; const bs = bottleneck(s, v, S_TREE); const bt = bottleneck(s, w, T_TREE);
    var amount: i64 = c;
    if (rs == s.source and rt == s.sink) {} else if (rs == s.source) { amount = min64(bs, c); }
    else if (rt == s.sink) { amount = min64(c, bt); }
    else { amount = min64(min64(min64(min64(s.balance[rs], bs), c), bt), -s.balance[rt]); }
    if (amount <= 0) return false;
    push(s, v, w, amount);
    repair(s);
    return true;
}

fn solve(s: *State) i64 {
    var finished = false;
    for (0..(4 * s.n + 4)) |_| {
        if (finished) break;
        while (true) {
            var restart = false;
            if (s.forward) {
                for (0..s.n) |v| {
                    if (restart) break;
                    if (s.kind[v] != S_TREE or s.ds[v] != s.ds_max) continue;
                    for (0..s.n) |w| {
                        if (s.residual[v * N_MAX + w] <= 0 or s.kind[w] == S_TREE) continue;
                        if (s.kind[w] == FREE_TREE) { s.kind[w] = S_TREE; s.parent[w] = @intCast(v); s.ds[w] = s.ds_max + 1; }
                        else if (s.kind[w] == T_TREE and augment(s, v, w)) { s.events += 1; if (s.events > EVENT_MAX) return -1; restart = true; break; }
                    }
                }
                if (!restart) {
                    var next = false; for (0..s.n) |v| { if (s.kind[v] == S_TREE and s.ds[v] == s.ds_max + 1) next = true; }
                    if (next) s.ds_max += 1 else finished = true;
                    break;
                }
            } else {
                for (0..s.n) |w| {
                    if (restart) break;
                    if (s.kind[w] != T_TREE or s.dt[w] != s.dt_max) continue;
                    for (0..s.n) |v| {
                        if (s.residual[v * N_MAX + w] <= 0 or s.kind[v] == T_TREE) continue;
                        if (s.kind[v] == FREE_TREE) { s.kind[v] = T_TREE; s.parent[v] = @intCast(w); s.dt[v] = s.dt_max + 1; }
                        else if (s.kind[v] == S_TREE and augment(s, v, w)) { s.events += 1; if (s.events > EVENT_MAX) return -1; restart = true; break; }
                    }
                }
                if (!restart) {
                    var next = false; for (0..s.n) |v| { if (s.kind[v] == T_TREE and s.dt[v] == s.dt_max + 1) next = true; }
                    if (next) s.dt_max += 1 else finished = true;
                    break;
                }
            }
        }
        if (!finished) s.forward = !s.forward;
    }
    var reachable: [8]bool = @splat(false);
    var queue: [8]usize = undefined;
    var head: usize = 0; var tail: usize = 0;
    for (0..s.n) |v| { if (s.kind[v] == S_TREE) { reachable[v] = true; queue[tail] = v; tail += 1; } }
    while (head < tail) {
        const u = queue[head]; head += 1;
        for (0..s.n) |v| { if (s.residual[u * N_MAX + v] > 0 and !reachable[v]) { reachable[v] = true; queue[tail] = v; tail += 1; } }
    }
    var cut: i64 = 0;
    for (0..s.n) |u| { if (reachable[u]) for (0..s.n) |v| { if (!reachable[v]) cut += s.original[u * N_MAX + v]; } }
    return cut;
}

export fn eibfs_maxflow(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 4 or length > INPUT_MAX) return -1;
    const input = input_opt.?;
    const nv = input[0]; const mv = input[1]; const sv = input[2]; const tv = input[3];
    if (nv < 2 or nv > N_MAX or mv < 0 or mv > M_MAX or sv < 0 or sv >= nv or tv < 0 or tv >= nv or sv == tv) return -1;
    const n: usize = @intCast(nv); const m: usize = @intCast(mv); const source: usize = @intCast(sv); const sink: usize = @intCast(tv);
    if (length != 4 + 3 * m) return -1;
    var s = State{ .n = n, .source = source, .sink = sink, .forward = true, .kind = @splat(FREE_TREE), .parent = @splat(-1), .original = @splat(0), .residual = @splat(0), .balance = @splat(0), .ds = @splat(0), .dt = @splat(0), .ds_max = 0, .dt_max = 0, .orphaned = @splat(false), .events = 0 };
    for (0..m) |e| {
        const u = input[4 + 3 * e]; const v = input[5 + 3 * e]; const c = input[6 + 3 * e];
        if (u < 0 or u >= nv or v < 0 or v >= nv or u == v or c < 0 or c > 100) return -1;
        const ui: usize = @intCast(u); const vi: usize = @intCast(v);
        s.original[ui * N_MAX + vi] += c; s.residual[ui * N_MAX + vi] += c;
    }
    s.kind[source] = S_TREE; s.kind[sink] = T_TREE;
    return solve(&s);
}
