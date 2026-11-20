const MAX_N: usize = 8;
const MAX_M: usize = 28;
const MAX_INPUT: usize = 67;
const MAX_PIECES: usize = 56;
const MAX_SPLITS: usize = 28;
const MODULUS: i64 = 998_244_353;
const KIND_S: i32 = 1;
const KIND_P: i32 = 2;

const EdgeRef = struct { u: usize = 0, v: usize = 0, pair_id: i32 = -1, real: bool = true };
const Piece = struct { edge_count: usize = 0, edges: [MAX_M]EdgeRef = [_]EdgeRef{.{}} ** MAX_M };

fn connectedWithout(adjacency: []const bool, n: usize, removed: i32) bool {
    var start: usize = 0;
    while (@as(i32, @intCast(start)) == removed) start += 1;
    var seen = [_]bool{false} ** MAX_N;
    var queue = [_]usize{0} ** MAX_N;
    seen[start] = true;
    queue[0] = start;
    var head: usize = 0;
    var tail: usize = 1;
    while (head < tail) : (head += 1) {
        const u = queue[head];
        for (0..n) |v| {
            if (@as(i32, @intCast(v)) != removed and adjacency[u * MAX_N + v] and !seen[v]) {
                seen[v] = true;
                queue[tail] = v;
                tail += 1;
            }
        }
    }
    var reached: usize = 0;
    for (0..n) |v| if (@as(i32, @intCast(v)) != removed and seen[v]) { reached += 1; };
    return reached == n - @as(usize, if (removed >= 0) 1 else 0);
}

fn componentsAfterPair(piece: *const Piece, n: usize, a: usize, b: usize, component: *[MAX_N]i32, count: *usize) void {
    component.* = [_]i32{-1} ** MAX_N;
    count.* = 0;
    var queue = [_]usize{0} ** MAX_N;
    for (0..n) |start| {
        if (start == a or start == b or component[start] >= 0) continue;
        var head: usize = 0;
        var tail: usize = 1;
        component[start] = @intCast(count.*);
        queue[0] = start;
        while (head < tail) : (head += 1) {
            const u = queue[head];
            for (piece.edges[0..piece.edge_count]) |edge| {
                if (edge.u == a or edge.u == b or edge.v == a or edge.v == b) continue;
                const other: ?usize = if (edge.u == u) edge.v else if (edge.v == u) edge.u else null;
                if (other) |v| if (component[v] < 0) {
                    component[v] = @intCast(count.*);
                    queue[tail] = v;
                    tail += 1;
                };
            }
        }
        count.* += 1;
    }
}

fn findSplit(piece: *const Piece, n: usize, chosen_u: *usize, chosen_v: *usize, left_edge: *[MAX_M]bool) bool {
    for (0..n) |u| for (u + 1..n) |v| {
        var component: [MAX_N]i32 = undefined;
        var component_count: usize = 0;
        componentsAfterPair(piece, n, u, v, &component, &component_count);
        var edge_class = [_]usize{0} ** MAX_M;
        var sizes = [_]usize{0} ** MAX_M;
        var direct_count: usize = 0;
        for (piece.edges[0..piece.edge_count], 0..) |edge, e| {
            if ((edge.u == u and edge.v == v) or (edge.u == v and edge.v == u)) {
                edge_class[e] = component_count + direct_count;
                direct_count += 1;
            } else {
                const endpoint = if (edge.u != u and edge.u != v) edge.u else edge.v;
                if (component[endpoint] < 0) return false;
                edge_class[e] = @intCast(component[endpoint]);
            }
            if (edge_class[e] >= MAX_M) return false;
            sizes[edge_class[e]] += 1;
        }
        const class_count = component_count + direct_count;
        var selected: ?usize = null;
        for (0..class_count) |c| if (sizes[c] >= 2 and sizes[c] <= piece.edge_count - 2) { selected = c; break; };
        var use_first_two = selected == null and class_count >= 4 and class_count == piece.edge_count;
        if (use_first_two) for (0..class_count) |c| {
            if (sizes[c] != 1) use_first_two = false;
        };
        if (selected == null and !use_first_two) continue;
        for (0..piece.edge_count) |e| left_edge[e] = if (selected) |c| edge_class[e] == c else edge_class[e] < 2;
        chosen_u.* = u;
        chosen_v.* = v;
        return true;
    };
    return false;
}

fn pieceKind(piece: *const Piece) i32 {
    var present = [_]bool{false} ** MAX_N;
    var vertex_count: usize = 0;
    for (piece.edges[0..piece.edge_count]) |edge| for ([_]usize{ edge.u, edge.v }) |v| {
        if (!present[v]) { present[v] = true; vertex_count += 1; }
    };
    if (vertex_count == 2 and piece.edge_count >= 3) return KIND_P;
    if (vertex_count == 3 and piece.edge_count == 3) {
        var pair = [_]bool{false} ** (MAX_N * MAX_N);
        for (piece.edges[0..3]) |edge| { pair[edge.u * MAX_N + edge.v] = true; pair[edge.v * MAX_N + edge.u] = true; }
        var count: usize = 0;
        for (0..MAX_N) |u| for (u + 1..MAX_N) |v| { if (pair[u * MAX_N + v]) count += 1; };
        if (count == 3) return KIND_S;
    }
    return 3;
}

fn findRoot(parent: *[MAX_PIECES]usize, item: usize) usize {
    var current = item;
    while (parent[current] != current) { parent[current] = parent[parent[current]]; current = parent[current]; }
    return current;
}
fn unite(parent: *[MAX_PIECES]usize, left: usize, right: usize) void {
    const a = findRoot(parent, left);
    const b = findRoot(parent, right);
    if (a != b) parent[b] = a;
}

fn pairComponents(adjacency: []const bool, n: usize, a: usize, b: usize) usize {
    var seen = [_]bool{false} ** MAX_N;
    var queue = [_]usize{0} ** MAX_N;
    var count: usize = 0;
    for (0..n) |start| {
        if (start == a or start == b or seen[start]) continue;
        count += 1;
        var head: usize = 0;
        var tail: usize = 1;
        seen[start] = true;
        queue[0] = start;
        while (head < tail) : (head += 1) {
            const u = queue[head];
            for (0..n) |v| if (v != a and v != b and adjacency[u * MAX_N + v] and !seen[v]) {
                seen[v] = true;
                queue[tail] = v;
                tail += 1;
            };
        }
    }
    return count;
}

fn solve(values: []const i64) i64 {
    if (values.len < 2 or values.len > MAX_INPUT) return -1;
    const n64 = values[0];
    const m64 = values[1];
    if (n64 < 3 or n64 > @as(i64, @intCast(MAX_N)) or m64 < 3 or m64 > @as(i64, @intCast(MAX_M))) return -1;
    const n: usize = @intCast(n64);
    const m: usize = @intCast(m64);
    if (values.len != 2 + n + 2 * m) return -1;
    var weights = [_]i64{0} ** MAX_N;
    for (0..n) |v| { weights[v] = values[2 + v]; if (weights[v] < 0 or weights[v] > 1_000_000) return -1; }
    var adjacency = [_]bool{false} ** (MAX_N * MAX_N);
    var pieces = [_]Piece{.{}} ** MAX_PIECES;
    pieces[0].edge_count = m;
    const offset = 2 + n;
    for (0..m) |e| {
        const a = values[offset + 2 * e];
        const b = values[offset + 2 * e + 1];
        if (a < 0 or a >= n64 or b < 0 or b >= n64 or a == b) return -1;
        const u: usize = @intCast(a);
        const v: usize = @intCast(b);
        if (adjacency[u * MAX_N + v]) return -1;
        adjacency[u * MAX_N + v] = true;
        adjacency[v * MAX_N + u] = true;
        pieces[0].edges[e] = .{ .u = u, .v = v, .pair_id = -1, .real = true };
    }
    for (0..n) |removed| if (!connectedWithout(&adjacency, n, @intCast(removed))) return -1;
    if (!connectedWithout(&adjacency, n, -1)) return -1;

    var piece_count: usize = 1;
    var split_count: usize = 0;
    var pair_u = [_]usize{0} ** MAX_SPLITS;
    var pair_v = [_]usize{0} ** MAX_SPLITS;
    var is_leaf = [_]bool{false} ** MAX_PIECES;
    var index: usize = 0;
    while (index < piece_count) : (index += 1) {
        var left_edge = [_]bool{false} ** MAX_M;
        var u: usize = 0;
        var v: usize = 0;
        if (!findSplit(&pieces[index], n, &u, &v, &left_edge)) { is_leaf[index] = true; continue; }
        if (split_count >= MAX_SPLITS or piece_count + 2 > MAX_PIECES) return -1;
        const left_index = piece_count;
        const right_index = piece_count + 1;
        piece_count += 2;
        for (pieces[index].edges[0..pieces[index].edge_count], 0..) |edge, e| {
            const target = if (left_edge[e]) left_index else right_index;
            pieces[target].edges[pieces[target].edge_count] = edge;
            pieces[target].edge_count += 1;
        }
        const pair_id: i32 = @intCast(split_count);
        pair_u[split_count] = u;
        pair_v[split_count] = v;
        split_count += 1;
        pieces[left_index].edges[pieces[left_index].edge_count] = .{ .u = u, .v = v, .pair_id = pair_id, .real = false };
        pieces[left_index].edge_count += 1;
        pieces[right_index].edges[pieces[right_index].edge_count] = .{ .u = u, .v = v, .pair_id = pair_id, .real = false };
        pieces[right_index].edge_count += 1;
        if (pieces[left_index].edge_count < 3 or pieces[right_index].edge_count < 3) return -1;
    }

    var kind = [_]i32{0} ** MAX_PIECES;
    var first_leaf = [_]usize{MAX_PIECES} ** MAX_SPLITS;
    var second_leaf = [_]usize{MAX_PIECES} ** MAX_SPLITS;
    var occurrences = [_]usize{0} ** MAX_SPLITS;
    var parent = [_]usize{0} ** MAX_PIECES;
    for (0..piece_count) |p| { parent[p] = p; if (is_leaf[p]) kind[p] = pieceKind(&pieces[p]); }
    for (0..piece_count) |p| if (is_leaf[p]) {
        for (pieces[p].edges[0..pieces[p].edge_count]) |edge| {
            if (edge.real) continue;
            if (edge.pair_id < 0 or @as(usize, @intCast(edge.pair_id)) >= split_count) return -1;
            const id: usize = @intCast(edge.pair_id);
            occurrences[id] += 1;
            if (occurrences[id] == 1) first_leaf[id] = p else if (occurrences[id] == 2) second_leaf[id] = p else return -1;
        }
    };
    for (0..split_count) |id| {
        if (occurrences[id] != 2 or first_leaf[id] == second_leaf[id]) return -1;
        const a = first_leaf[id];
        const b = second_leaf[id];
        if (kind[a] == kind[b] and (kind[a] == KIND_S or kind[a] == KIND_P)) unite(&parent, a, b);
    }
    var candidate = [_]bool{false} ** (MAX_N * MAX_N);
    for (0..split_count) |id| candidate[pair_u[id] * MAX_N + pair_v[id]] = true;
    for (0..piece_count) |leaf| {
        if (!is_leaf[leaf] or findRoot(&parent, leaf) != leaf) continue;
        if (kind[leaf] == KIND_S) {
            var in_group = [_]bool{false} ** MAX_N;
            var skeleton = [_]bool{false} ** (MAX_N * MAX_N);
            for (0..piece_count) |member| if (is_leaf[member] and findRoot(&parent, member) == leaf) {
                for (pieces[member].edges[0..pieces[member].edge_count]) |edge| {
                    if (!edge.real) {
                        const id: usize = @intCast(edge.pair_id);
                        if (findRoot(&parent, first_leaf[id]) == leaf and findRoot(&parent, second_leaf[id]) == leaf) continue;
                    }
                    in_group[edge.u] = true;
                    in_group[edge.v] = true;
                    skeleton[edge.u * MAX_N + edge.v] = true;
                    skeleton[edge.v * MAX_N + edge.u] = true;
                }
            };
            for (0..n) |u| for (u + 1..n) |v| {
                if (in_group[u] and in_group[v] and !skeleton[u * MAX_N + v]) candidate[u * MAX_N + v] = true;
            };
        } else if (kind[leaf] == KIND_P) {
            var first: ?usize = null;
            var second: ?usize = null;
            for (0..piece_count) |member| if (is_leaf[member] and findRoot(&parent, member) == leaf) {
                for (pieces[member].edges[0..pieces[member].edge_count]) |edge| for ([_]usize{ edge.u, edge.v }) |endpoint| {
                    if (first == null) first = endpoint else if (endpoint != first.?) {
                        if (second == null) second = endpoint else if (endpoint != second.?) return -1;
                    }
                };
            };
            if (first == null or second == null) return -1;
            const u = @min(first.?, second.?);
            const v = @max(first.?, second.?);
            candidate[u * MAX_N + v] = true;
        }
    }
    var total: i64 = 0;
    for (0..n) |u| for (u + 1..n) |v| if (candidate[u * MAX_N + v]) {
        const components = pairComponents(&adjacency, n, u, v);
        if (components > 1) {
            const term = (weights[u] % MODULUS) * (weights[v] % MODULUS) % MODULUS;
            total = (total + term * @as(i64, @intCast(components - 1))) % MODULUS;
        }
    };
    return total;
}

export fn two_vertex_cuts_spqr(input: ?[*]const i64, length: usize) i64 {
    if (input == null or length < 2 or length > MAX_INPUT) return -1;
    return solve(input.?[0..length]);
}
