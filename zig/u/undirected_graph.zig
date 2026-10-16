const MAX_VERTICES: usize = 8;
const MAX_EDGES: usize = 28;
const MAX_OPERATIONS: usize = 128;
const MAX_INPUT_LENGTH: usize = 599;
const MIN_WEIGHT: i64 = -1_000_000;
const MAX_WEIGHT: i64 = 1_000_000;
const FNV_OFFSET: u64 = 0xcbf29ce484222325;
const FNV_PRIME: u64 = 0x100000001b3;
const RESULT_MASK: u64 = 0x7fffffffffffffff;

const Forest = struct { components: usize, edge_mask: u32 };

fn hashByte(hash: u64, value: u8) u64 {
    return (hash ^ value) *% FNV_PRIME;
}

fn hashI32(hash_value: u64, value: i64) u64 {
    var hash = hash_value;
    const bits: u32 = @bitCast(@as(i32, @intCast(value)));
    for (0..4) |index| hash = hashByte(hash, @truncate(bits >> @as(u5, @intCast(index * 8))));
    return hash;
}

fn hashU32(hash_value: u64, value: u32) u64 {
    var hash = hash_value;
    for (0..4) |index| hash = hashByte(hash, @truncate(value >> @as(u5, @intCast(index * 8))));
    return hash;
}

fn edgeBitIndex(n: usize, u_input: usize, v_input: usize) usize {
    var u = u_input;
    var v = v_input;
    if (u > v) { const temp = u; u = v; v = temp; }
    var index: usize = 0;
    for (0..u) |first| index += n - first - 1;
    return index + v - u - 1;
}

fn componentCount(n: usize, present: *const [64]u8) usize {
    var seen = [_]bool{false} ** MAX_VERTICES;
    var count: usize = 0;
    for (0..n) |root| {
        if (seen[root]) continue;
        count += 1;
        seen[root] = true;
        var stack = [_]usize{0} ** MAX_VERTICES;
        var size: usize = 1;
        stack[0] = root;
        while (size > 0) {
            size -= 1;
            const node = stack[size];
            for (0..n) |neighbor| {
                if (present[node * MAX_VERTICES + neighbor] != 0 and !seen[neighbor]) {
                    seen[neighbor] = true;
                    stack[size] = neighbor;
                    size += 1;
                }
            }
        }
    }
    return count;
}

fn primForest(n: usize, present: *const [64]u8, weights: *const [64]i64) Forest {
    var in_forest = [_]bool{false} ** MAX_VERTICES;
    var best_weight = [_]i64{0} ** MAX_VERTICES;
    var best_parent = [_]i32{-1} ** MAX_VERTICES;
    var components: usize = 0;
    var edge_mask: u32 = 0;
    for (0..n) |root| {
        if (in_forest[root]) continue;
        components += 1;
        in_forest[root] = true;
        for (0..n) |neighbor| {
            const index = root * MAX_VERTICES + neighbor;
            if (present[index] != 0 and !in_forest[neighbor]) {
                best_weight[neighbor] = weights[index];
                best_parent[neighbor] = @intCast(root);
            }
        }
        while (true) {
            var selected: ?usize = null;
            for (0..n) |candidate| {
                if (in_forest[candidate] or best_parent[candidate] < 0) continue;
                if (selected == null or best_weight[candidate] < best_weight[selected.?]) selected = candidate;
            }
            const node = selected orelse break;
            const parent: usize = @intCast(best_parent[node]);
            edge_mask |= @as(u32, 1) << @intCast(edgeBitIndex(n, parent, node));
            in_forest[node] = true;
            best_parent[node] = -1;
            for (0..n) |neighbor| {
                const index = node * MAX_VERTICES + neighbor;
                if (present[index] != 0 and !in_forest[neighbor] and
                    (best_parent[neighbor] < 0 or weights[index] < best_weight[neighbor])) {
                    best_weight[neighbor] = weights[index];
                    best_parent[neighbor] = @intCast(node);
                }
            }
        }
    }
    return .{ .components = components, .edge_mask = edge_mask };
}

fn findRoot(parent: *[MAX_VERTICES]usize, node_input: usize) usize {
    var node = node_input;
    while (parent[node] != node) {
        parent[node] = parent[parent[node]];
        node = parent[node];
    }
    return node;
}

fn kruskalForest(n: usize, present: *const [64]u8, weights: *const [64]i64) Forest {
    var edge_u = [_]usize{0} ** MAX_EDGES;
    var edge_v = [_]usize{0} ** MAX_EDGES;
    var edge_weight = [_]i64{0} ** MAX_EDGES;
    var edge_count: usize = 0;
    for (0..n) |u| {
        for (u + 1..n) |v| {
            const index = u * MAX_VERTICES + v;
            if (present[index] == 0) continue;
            edge_u[edge_count] = u;
            edge_v[edge_count] = v;
            edge_weight[edge_count] = weights[index];
            edge_count += 1;
        }
    }
    for (1..edge_count) |i| {
        const u = edge_u[i];
        const v = edge_v[i];
        const weight = edge_weight[i];
        var j = i;
        while (j > 0 and edge_weight[j - 1] > weight) : (j -= 1) {
            edge_u[j] = edge_u[j - 1];
            edge_v[j] = edge_v[j - 1];
            edge_weight[j] = edge_weight[j - 1];
        }
        edge_u[j] = u;
        edge_v[j] = v;
        edge_weight[j] = weight;
    }
    var parent = [_]usize{0} ** MAX_VERTICES;
    var rank = [_]u8{0} ** MAX_VERTICES;
    for (0..n) |index| parent[index] = index;
    var components = n;
    var edge_mask: u32 = 0;
    for (0..edge_count) |i| {
        const left = findRoot(&parent, edge_u[i]);
        const right = findRoot(&parent, edge_v[i]);
        if (left == right) continue;
        if (rank[left] < rank[right]) parent[left] = right
        else if (rank[left] > rank[right]) parent[right] = left
        else { parent[right] = left; rank[left] += 1; }
        components -= 1;
        edge_mask |= @as(u32, 1) << @intCast(edgeBitIndex(n, edge_u[i], edge_v[i]));
    }
    return .{ .components = components, .edge_mask = edge_mask };
}

export fn undirected_graph(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 3 or length > MAX_INPUT_LENGTH) return -1;
    const n_value = input[0];
    const initial_count_value = input[1];
    if (n_value < 0 or n_value > MAX_VERTICES or initial_count_value < 0 or initial_count_value > MAX_EDGES) return -1;
    const n: usize = @intCast(n_value);
    const initial_count: usize = @intCast(initial_count_value);
    if (initial_count > n * (n - 1) / 2) return -1;
    const count_position = 2 + 3 * initial_count;
    if (count_position >= length) return -1;
    const operation_count_value = input[count_position];
    if (operation_count_value < 0 or operation_count_value > MAX_OPERATIONS or
        length != 3 + 3 * initial_count + 4 * @as(usize, @intCast(operation_count_value))) return -1;

    var present = [_]u8{0} ** 64;
    var weights = [_]i64{0} ** 64;
    for (0..initial_count) |edge| {
        const position = 2 + 3 * edge;
        const u_value = input[position];
        const v_value = input[position + 1];
        const weight = input[position + 2];
        if (u_value < 0 or u_value >= v_value or v_value >= n_value or weight < MIN_WEIGHT or weight > MAX_WEIGHT) return -1;
        const u: usize = @intCast(u_value);
        const v: usize = @intCast(v_value);
        if (present[u * MAX_VERTICES + v] != 0) return -1;
        for (0..n) |first| {
            for (first + 1..n) |second| {
                const index = first * MAX_VERTICES + second;
                if (present[index] != 0 and weights[index] == weight) return -1;
            }
        }
        present[u * MAX_VERTICES + v] = 1;
        present[v * MAX_VERTICES + u] = 1;
        weights[u * MAX_VERTICES + v] = weight;
        weights[v * MAX_VERTICES + u] = weight;
    }

    var hash = FNV_OFFSET;
    for (0..@as(usize, @intCast(operation_count_value))) |operation| {
        const position = count_position + 1 + 4 * operation;
        const opcode = input[position];
        const u_value = input[position + 1];
        const v_value = input[position + 2];
        const weight = input[position + 3];
        var result_code: u8 = 0;
        if (opcode == 0) {
            if (u_value < 0 or u_value >= n_value or v_value < 0 or v_value >= n_value or u_value == v_value or
                weight < MIN_WEIGHT or weight > MAX_WEIGHT) return -1;
            const u: usize = @intCast(u_value);
            const v: usize = @intCast(v_value);
            const index = u * MAX_VERTICES + v;
            const reverse = v * MAX_VERTICES + u;
            const old_index = if (u < v) index else reverse;
            for (0..n) |first| {
                for (first + 1..n) |second| {
                    const other = first * MAX_VERTICES + second;
                    if (other != old_index and present[other] != 0 and weights[other] == weight) return -1;
                }
            }
            present[index] = 1;
            present[reverse] = 1;
            weights[index] = weight;
            weights[reverse] = weight;
        } else if (opcode == 1 or opcode == 2) {
            if (u_value < 0 or u_value >= n_value or v_value < 0 or v_value >= n_value or u_value == v_value or weight != 0) return -1;
            const u: usize = @intCast(u_value);
            const v: usize = @intCast(v_value);
            const index = u * MAX_VERTICES + v;
            const reverse = v * MAX_VERTICES + u;
            if (opcode == 1) {
                present[index] = 0;
                present[reverse] = 0;
                weights[index] = 0;
                weights[reverse] = 0;
            } else result_code = present[index];
        } else if (opcode == 3) {
            if (u_value != 0 or v_value != 0 or weight != 0) return -1;
            hash = hashByte(hash, @intCast(opcode));
            hash = hashByte(hash, result_code);
            hash = hashByte(hash, @intCast(componentCount(n, &present)));
            continue;
        } else if (opcode == 4 or opcode == 5 or opcode == 6) {
            if (u_value != 0 or v_value != 0 or weight != 0) return -1;
            const summary = if (opcode == 5) kruskalForest(n, &present, &weights) else primForest(n, &present, &weights);
            hash = hashByte(hash, @intCast(opcode));
            hash = hashByte(hash, result_code);
            hash = hashByte(hash, @intCast(summary.components));
            hash = hashU32(hash, summary.edge_mask);
            continue;
        } else return -1;
        hash = hashByte(hash, @intCast(opcode));
        hash = hashByte(hash, result_code);
    }

    var active_count: usize = 0;
    for (0..n) |u| for (u + 1..n) |v| {
        if (present[u * MAX_VERTICES + v] != 0) active_count += 1;
    };
    hash = hashByte(hash, @intCast(n));
    hash = hashByte(hash, @intCast(active_count));
    for (0..n) |u| {
        for (u + 1..n) |v| {
            const index = u * MAX_VERTICES + v;
            if (present[index] == 0) continue;
            hash = hashByte(hash, @intCast(u));
            hash = hashByte(hash, @intCast(v));
            hash = hashI32(hash, weights[index]);
        }
    }
    return @intCast(hash & RESULT_MASK);
}
