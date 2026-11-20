const PF_N = 8;
const PF_K = 6;
const PF_M = 24;
const PF_ITERATIONS = 512;

fn pfBuildState(k: usize, root_edge: *const [PF_K]bool, tree_edges: *const [PF_N]usize, tree_count: usize,
                edge_u: *const [PF_M]usize, edge_v: *const [PF_M]usize, parent: *[PF_N + 1]i32,
                parent_edge: *[PF_N + 1]i32, branch_root: *[PF_K]i32) bool {
    const root = k;
    var adjacency: [81]i32 = @splat(-2);
    for (0..k) |v| {
        if (root_edge.*[v]) { adjacency[root * 9 + v] = -1; adjacency[v * 9 + root] = -1; }
    }
    for (0..tree_count) |i| {
        const e = tree_edges.*[i];
        const u = edge_u.*[e];
        const v = edge_v.*[e];
        adjacency[u * 9 + v] = @intCast(e);
        adjacency[v * 9 + u] = @intCast(e);
    }
    for (0..PF_N + 1) |i| { parent.*[i] = -2; parent_edge.*[i] = -2; }
    for (0..k) |i| { branch_root.*[i] = -1; }
    var queue: [PF_N + 1]usize = @splat(0);
    var head: usize = 0;
    var tail: usize = 1;
    parent.*[root] = -1;
    queue[0] = root;
    while (head < tail) {
        const u = queue[head]; head += 1;
        for (0..k + 1) |v| {
            if (adjacency[u * 9 + v] != -2 and parent.*[v] == -2) {
                parent.*[v] = @intCast(u);
                parent_edge.*[v] = adjacency[u * 9 + v];
                branch_root.*[v] = if (u == root) @intCast(v) else branch_root.*[u];
                queue[tail] = v; tail += 1;
            }
        }
    }
    return tail == k + 1;
}

fn pfBalance(k: usize, edge_count: usize, weight: *const [PF_K]i64, edge_u: *const [PF_M]usize,
             edge_v: *const [PF_M]usize, flow: *const [PF_M]i64, balance: *[PF_K]i64) void {
    for (0..k) |v| { balance.*[v] = weight.*[v]; }
    for (0..edge_count) |e| { balance.*[edge_u.*[e]] -= flow.*[e]; balance.*[edge_v.*[e]] += flow.*[e]; }
}

fn pfInTree(tree_edges: *const [PF_N]usize, tree_count: usize, edge: usize) bool {
    for (0..tree_count) |i| { if (tree_edges.*[i] == edge) return true; }
    return false;
}

fn pfRemoveTreeEdge(tree_edges: *[PF_N]usize, tree_count: *usize, edge: usize) bool {
    for (0..tree_count.*) |i| {
        if (tree_edges.*[i] == edge) {
            var j = i;
            while (j + 1 < tree_count.*) : (j += 1) { tree_edges.*[j] = tree_edges.*[j + 1]; }
            tree_count.* -= 1;
            return true;
        }
    }
    return false;
}

export fn hochbaum_pseudoflow_maxflow(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 4 or length > 77) return -1;
    const input = input_opt.?;
    const nv = input[0]; const mv = input[1]; const sr = input[2]; const tr = input[3];
    if (nv < 2 or nv > 8 or mv < 0 or mv > 24 or sr < 1 or sr > nv or tr < 1 or tr > nv or sr == tr) return -1;
    const n: usize = @intCast(nv); const m: usize = @intCast(mv);
    const source: usize = @intCast(sr - 1); const sink: usize = @intCast(tr - 1);
    if (length != 4 + 3 * m) return -1;
    var local: [PF_N]i32 = @splat(-1);
    var k: usize = 0;
    for (0..n) |v| { if (v != source and v != sink) { local[v] = @intCast(k); k += 1; } }
    var source_cap: [PF_K]i64 = @splat(0);
    var sink_cap: [PF_K]i64 = @splat(0);
    var direct_cap: i64 = 0;
    var edge_u: [PF_M]usize = @splat(0);
    var edge_v: [PF_M]usize = @splat(0);
    var capacity: [PF_M]i64 = @splat(0);
    var flow: [PF_M]i64 = @splat(0);
    var edge_count: usize = 0;
    for (0..m) |i| {
        const ur = input[4 + 3 * i]; const vr = input[5 + 3 * i]; const cap = input[6 + 3 * i];
        if (ur < 1 or ur > nv or vr < 1 or vr > nv or ur == vr or cap < 0 or cap > 100) return -1;
        const u: usize = @intCast(ur - 1); const v: usize = @intCast(vr - 1);
        if (u == source) {
            if (v == sink) { direct_cap += cap; } else { source_cap[@intCast(local[v])] += cap; }
        } else if (v == sink) { sink_cap[@intCast(local[u])] += cap; }
        else if (v == source or u == sink) return -1
        else { edge_u[edge_count] = @intCast(local[u]); edge_v[edge_count] = @intCast(local[v]); capacity[edge_count] = cap; edge_count += 1; }
    }
    var weight: [PF_K]i64 = @splat(0); var balance: [PF_K]i64 = @splat(0);
    var label: [PF_K]i64 = @splat(0); var ticket: [PF_K]i64 = @splat(0);
    var next_ticket: i64 = 0;
    var root_edge: [PF_K]bool = @splat(false);
    var tree_edges: [PF_N]usize = @splat(0);
    var tree_count: usize = 0;
    for (0..k) |v| { weight[v] = source_cap[v] - sink_cap[v]; root_edge[v] = true; label[v] = 1; ticket[v] = next_ticket; next_ticket += 1; }
    var parent: [PF_N + 1]i32 = @splat(0); var parent_edge: [PF_N + 1]i32 = @splat(0); var branch_root: [PF_K]i32 = @splat(0);
    for (0..PF_ITERATIONS) |_| {
        pfBalance(k, edge_count, &weight, &edge_u, &edge_v, &flow, &balance);
        if (!pfBuildState(k, &root_edge, &tree_edges, tree_count, &edge_u, &edge_v, &parent, &parent_edge, &branch_root)) return -1;
        var active: [PF_K]bool = @splat(false); var strong: [PF_K]bool = @splat(false); const old_label = label;
        for (0..k) |r| { if (root_edge[r] and balance[r] > 0) active[r] = true; }
        for (0..k) |v| { strong[v] = balance[@intCast(branch_root[v])] > 0; }
        var crossing = false;
        for (0..edge_count) |e| {
            const u = edge_u[e]; const v = edge_v[e];
            if (strong[u] and !strong[v] and capacity[e] - flow[e] > 0) crossing = true;
            if (strong[v] and !strong[u] and flow[e] > 0) crossing = true;
        }
        if (!crossing) {
            var cut = direct_cap;
            for (0..k) |v| { cut += if (strong[v]) sink_cap[v] else source_cap[v]; }
            for (0..edge_count) |e| { if (strong[edge_u[e]] and !strong[edge_v[e]]) cut += capacity[e]; }
            return if (cut >= 0 and cut <= 2400) cut else -1;
        }
        var strong_root: ?usize = null;
        for (0..k) |r| {
            if (active[r]) {
                if (strong_root == null or label[r] > label[strong_root.?] or (label[r] == label[strong_root.?] and ticket[r] < ticket[strong_root.?])) strong_root = r;
            }
        }
        const sr = strong_root orelse return -1;
        var low: i64 = 1000;
        for (0..k) |v| { if (@as(usize, @intCast(branch_root[v])) == sr and label[v] < low) low = label[v]; }
        var tail: ?usize = null; var head_node: ?usize = null; var entering: ?usize = null;
        for (0..k) |v| {
            if (entering == null and @as(usize, @intCast(branch_root[v])) == sr and label[v] == low) {
                for (0..edge_count) |e| {
                    if (entering == null and !pfInTree(&tree_edges, tree_count, e)) {
                        const u = edge_u[e]; const w = edge_v[e];
                        if (u == v and capacity[e] - flow[e] > 0 and @as(usize, @intCast(branch_root[w])) != sr and label[w] == low - 1) { tail = v; head_node = w; entering = e; }
                        else if (w == v and flow[e] > 0 and @as(usize, @intCast(branch_root[u])) != sr and label[u] == low - 1) { tail = v; head_node = u; entering = e; }
                    }
                }
            }
        }
        if (entering == null) {
            var relabel: ?usize = null;
            for (0..k) |v| {
                if (relabel == null and @as(usize, @intCast(branch_root[v])) == sr and label[v] == low) {
                    var children_ok = true;
                    for (0..k) |child| { if (parent[child] == @as(i32, @intCast(v)) and label[child] < low + 1) children_ok = false; }
                    if (children_ok) relabel = v;
                }
            }
            const rv = relabel orelse return -1;
            label[rv] += 1;
            if (rv == sr) { ticket[sr] = next_ticket; next_ticket += 1; }
            continue;
        }
        const tail_v = tail.?; const head_v = head_node.?; const enter = entering.?;
        const target_root: usize = @intCast(branch_root[head_v]); const root = k;
        var chain: [PF_N + 1]usize = @splat(0); var chain_len: usize = 0; var cursor = tail_v;
        while (cursor != root) { chain[chain_len] = cursor; chain_len += 1; cursor = @intCast(parent[cursor]); }
        var step_from: [2 * PF_N + 2]usize = @splat(0); var step_to: [2 * PF_N + 2]usize = @splat(0); var step_edge: [2 * PF_N + 2]usize = @splat(0); var steps: usize = 0;
        var j = chain_len;
        while (j > 0) { j -= 1; const child = chain[j]; if (@as(usize, @intCast(parent[child])) != root) { step_from[steps] = @intCast(parent[child]); step_to[steps] = child; step_edge[steps] = @intCast(parent_edge[child]); steps += 1; } }
        step_from[steps] = tail_v; step_to[steps] = head_v; step_edge[steps] = enter; steps += 1;
        cursor = head_v;
        while (cursor != target_root) { step_from[steps] = cursor; step_to[steps] = @intCast(parent[cursor]); step_edge[steps] = @intCast(parent_edge[cursor]); steps += 1; cursor = @intCast(parent[cursor]); }
        root_edge[sr] = false; tree_edges[tree_count] = enter; tree_count += 1;
        for (0..chain_len) |i| { label[chain[i]] = label[head_v] + 1; }
        var carry = balance[sr];
        for (0..steps) |i| {
            const e = step_edge[i]; const u = edge_u[e]; const v = edge_v[e];
            const residual = if (step_from[i] == u and step_to[i] == v) capacity[e] - flow[e] else flow[e];
            const pushed = @min(carry, residual);
            if (step_from[i] == u and step_to[i] == v) { flow[e] += pushed; } else { flow[e] -= pushed; }
            if (residual < carry) { if (!pfRemoveTreeEdge(&tree_edges, &tree_count, e)) return -1; root_edge[step_from[i]] = true; }
            carry = pushed;
            if (carry == 0) break;
        }
        pfBalance(k, edge_count, &weight, &edge_u, &edge_v, &flow, &balance);
        if (!pfBuildState(k, &root_edge, &tree_edges, tree_count, &edge_u, &edge_v, &parent, &parent_edge, &branch_root)) return -1;
        for (0..k) |r| { if (root_edge[r] and balance[r] > 0 and (!active[r] or label[r] != old_label[r])) { ticket[r] = next_ticket; next_ticket += 1; } }
    }
    return -1;
}
