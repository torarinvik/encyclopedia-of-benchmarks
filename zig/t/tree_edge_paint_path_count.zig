const MAX_N: usize = 16;
const MAX_Q: usize = 32;
const MAX_EDGES: usize = 15;
const LOG_N: usize = 5;

fn rootOf(parent: []usize, node_arg: usize) usize {
    var node = node_arg;
    while (parent[node] != node) {
        parent[node] = parent[parent[node]];
        node = parent[node];
    }
    return node;
}

fn pointSet(tree: []i64, base: usize, index: usize, value: i64) void {
    var position = base + index;
    tree[position] = value;
    position /= 2;
    while (position > 0) {
        tree[position] = tree[2 * position] + tree[2 * position + 1];
        position /= 2;
    }
}

fn rangeSum(tree: []const i64, base: usize, left: usize, right: usize) i64 {
    if (left > right) return 0;
    var l = base + left;
    var r = base + right + 1;
    var total: i64 = 0;
    while (l < r) {
        if ((l & 1) == 1) { total += tree[l]; l += 1; }
        if ((r & 1) == 1) { r -= 1; total += tree[r]; }
        l /= 2;
        r /= 2;
    }
    return total;
}

fn lca(a_arg: usize, b_arg: usize, depth: []const usize, parent: []const usize, ancestor: []const usize) usize {
    var a = a_arg;
    var b = b_arg;
    if (depth[a] < depth[b]) { const temporary = a; a = b; b = temporary; }
    var difference = depth[a] - depth[b];
    var bit: usize = 0;
    while (difference != 0) : (bit += 1) {
        if ((difference & 1) != 0) a = ancestor[bit * MAX_N + a];
        difference >>= 1;
    }
    if (a == b) return a;
    var reverse = LOG_N;
    while (reverse > 0) {
        reverse -= 1;
        if (ancestor[reverse * MAX_N + a] != ancestor[reverse * MAX_N + b]) {
            a = ancestor[reverse * MAX_N + a];
            b = ancestor[reverse * MAX_N + b];
        }
    }
    return parent[a];
}

fn solve(input: []const i64) i64 {
    if (input.len < 2 or input.len > 129) return -1;
    if (input[0] < 1 or input[0] > @as(i64, @intCast(MAX_N)) or input[1] < 0 or input[1] > @as(i64, @intCast(MAX_Q))) return -1;
    const n: usize = @intCast(input[0]);
    const q: usize = @intCast(input[1]);
    const m = n - 1;
    if (input.len != 2 + 2 * m + 3 * q) return -1;

    var edge_u = [_]usize{0} ** MAX_EDGES;
    var edge_v = [_]usize{0} ** MAX_EDGES;
    var dsu = [_]usize{0} ** MAX_N;
    for (0..n) |i| dsu[i] = i;
    var cursor: usize = 2;
    for (0..m) |edge| {
        const u_value = input[cursor];
        const v_value = input[cursor + 1];
        cursor += 2;
        if (u_value < 0 or u_value >= @as(i64, @intCast(n)) or v_value < 0 or v_value >= @as(i64, @intCast(n)) or u_value == v_value) return -1;
        const u: usize = @intCast(u_value);
        const v: usize = @intCast(v_value);
        edge_u[edge] = u;
        edge_v[edge] = v;
        const ru = rootOf(&dsu, u);
        const rv = rootOf(&dsu, v);
        if (ru == rv) return -1;
        dsu[ru] = rv;
    }
    const tree_root = rootOf(&dsu, 0);
    for (1..n) |v| if (rootOf(&dsu, v) != tree_root) return -1;

    var parent = [_]usize{0} ** MAX_N;
    var depth = [_]usize{0} ** MAX_N;
    var first = [_]usize{0} ** MAX_N;
    var visited = [_]bool{false} ** MAX_N;
    var down = [_]usize{0} ** MAX_EDGES;
    var up = [_]usize{0} ** MAX_EDGES;
    var stack_node = [_]usize{0} ** MAX_N;
    var stack_parent = [_]usize{MAX_N} ** MAX_N;
    var stack_in = [_]usize{MAX_EDGES} ** MAX_N;
    var stack_cursor = [_]usize{0} ** MAX_N;
    visited[0] = true;
    var top: isize = 0;
    var occurrences: usize = 0;
    while (top >= 0) {
        const slot: usize = @intCast(top);
        const node = stack_node[slot];
        var found = false;
        while (stack_cursor[slot] < m) {
            const edge = stack_cursor[slot];
            stack_cursor[slot] += 1;
            if (edge_u[edge] != node and edge_v[edge] != node) continue;
            const child = if (edge_u[edge] == node) edge_v[edge] else edge_u[edge];
            if (child == stack_parent[slot]) continue;
            if (visited[child]) return -1;
            visited[child] = true;
            parent[child] = node;
            depth[child] = depth[node] + 1;
            down[edge] = occurrences;
            occurrences += 1;
            first[child] = occurrences;
            top += 1;
            const child_slot: usize = @intCast(top);
            stack_node[child_slot] = child;
            stack_parent[child_slot] = node;
            stack_in[child_slot] = edge;
            stack_cursor[child_slot] = 0;
            found = true;
            break;
        }
        if (!found) {
            const incoming = stack_in[slot];
            top -= 1;
            if (incoming != MAX_EDGES) { up[incoming] = occurrences; occurrences += 1; }
        }
    }

    var ancestor = [_]usize{0} ** (MAX_N * LOG_N);
    for (0..n) |v| ancestor[v] = parent[v];
    for (1..LOG_N) |k| for (0..n) |v| {
        ancestor[k * MAX_N + v] = ancestor[(k - 1) * MAX_N + ancestor[(k - 1) * MAX_N + v]];
    };
    var base: usize = 1;
    while (base < occurrences) base *= 2;
    var forward = [_]i64{0} ** 64;
    var backward = [_]i64{0} ** 64;
    var painted = [_]bool{false} ** MAX_EDGES;
    var total: i64 = 0;
    for (0..q) |_| {
        const kind = input[cursor];
        const a = input[cursor + 1];
        const b = input[cursor + 2];
        cursor += 3;
        if (kind == 0) {
            if (a < 0 or a >= @as(i64, @intCast(m)) or b != 0) return -1;
            const edge: usize = @intCast(a);
            if (!painted[edge]) {
                painted[edge] = true;
                pointSet(&forward, base, down[edge], 1);
                pointSet(&backward, base, up[edge], 1);
            }
        } else if (kind == 1) {
            if (a < 0 or a >= @as(i64, @intCast(n)) or b < 0 or b >= @as(i64, @intCast(n))) return -1;
            const u: usize = @intCast(a);
            const v: usize = @intCast(b);
            const common = lca(u, v, &depth, &parent, &ancestor);
            const left_a = first[common];
            const right_a = first[u] -| 1;
            const left_b = first[common];
            const right_b = first[v] -| 1;
            if (u != common) {
                total += rangeSum(&forward, base, left_a, right_a) - rangeSum(&backward, base, left_a, right_a);
            }
            if (v != common) {
                total += rangeSum(&forward, base, left_b, right_b) - rangeSum(&backward, base, left_b, right_b);
            }
        } else return -1;
    }
    return total;
}

export fn tree_edge_paint_path_count(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 2 or length > 129) return -1;
    return solve(input_opt.?[0..length]);
}
