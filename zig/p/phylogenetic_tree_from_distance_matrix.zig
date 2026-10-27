const MAX_N: usize = 6;
const MAX_NODES: usize = 10;
const MAX_EDGES: usize = 9;
const MAX_OUTPUT_BYTES: usize = 152;

fn store_i64_le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

fn tree_distance(node_count: usize, edge_count: usize, edge_u: *const [MAX_EDGES]i32,
    edge_v: *const [MAX_EDGES]i32, edge_w: *const [MAX_EDGES]i64,
    start: usize, target: usize, distance: *[MAX_NODES]i64) bool {
    var parent: [MAX_NODES]i32 = @splat(-1);
    var queue: [MAX_NODES]usize = @splat(0);
    parent[start] = @intCast(start);
    distance[start] = 0;
    var head: usize = 0;
    var tail: usize = 0;
    queue[tail] = start; tail += 1;
    while (head < tail) {
        const node = queue[head]; head += 1;
        if (node == target) return true;
        for (0..edge_count) |e| {
            const u: usize = @intCast(edge_u[e]);
            const v: usize = @intCast(edge_v[e]);
            const neighbor = if (u == node) v else if (v == node) u else MAX_NODES;
            if (neighbor == MAX_NODES or parent[neighbor] >= 0) continue;
            parent[neighbor] = @intCast(node);
            distance[neighbor] = distance[node] + edge_w[e];
            queue[tail] = neighbor; tail += 1;
        }
    }
    return false;
}

export fn phylogenetic_tree_from_distance_matrix(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 1 or length > MAX_N * MAX_N + 2) return -1;
    const input = input_opt.?;
    const raw_n = input[0];
    if (raw_n < 2 or raw_n > @as(i64, MAX_N) or length != 1 + @as(usize, @intCast(raw_n * raw_n))) return -1;
    const n: usize = @intCast(raw_n);
    var d: [MAX_N * MAX_N]i64 = @splat(0);
    for (0..n) |i| {
        for (0..n) |j| {
            const value = input[1 + i * n + j];
            if ((i == j and value != 0) or (i != j and (value < 1 or value > 32))) return -1;
            d[i * MAX_N + j] = value;
        }
    }
    for (0..n) |i| for (i + 1..n) |j| {
        if (d[i * MAX_N + j] != d[j * MAX_N + i]) return -1;
    };

    var edge_u: [MAX_EDGES]i32 = @splat(0);
    var edge_v: [MAX_EDGES]i32 = @splat(0);
    var edge_w: [MAX_EDGES]i64 = @splat(0);
    var edge_count: usize = 1;
    edge_u[0] = 0; edge_v[0] = 1; edge_w[0] = 2 * d[1];
    var label_node: [MAX_N]usize = @splat(0);
    label_node[1] = 1;
    var label_mask: [MAX_NODES]u32 = @splat(0);
    label_mask[0] = 1; label_mask[1] = 2;
    var node_count: usize = 2;
    var additive = true;

    for (2..n) |leaf| {
        if (!additive) break;
        var limb2: i64 = std.math.maxInt(i64);
        for (0..leaf) |i| for (i + 1..leaf) |j| {
            const candidate = d[i * MAX_N + leaf] + d[j * MAX_N + leaf] - d[i * MAX_N + j];
            if (candidate < limb2) limb2 = candidate;
        };
        if (limb2 < 0) { additive = false; break; }
        var witness_i: usize = MAX_N;
        var witness_j: usize = MAX_N;
        var attach_distance: i64 = 0;
        for (0..leaf) |i| {
            if (witness_i != MAX_N) break;
            for (i + 1..leaf) |j| {
                const from_i = 2 * d[i * MAX_N + leaf] - limb2;
                const from_j = 2 * d[j * MAX_N + leaf] - limb2;
                if (from_i >= 0 and from_j >= 0 and 2 * d[i * MAX_N + j] == from_i + from_j) {
                    witness_i = i; witness_j = j; attach_distance = from_i; break;
                }
            }
        }
        if (witness_i == MAX_N) { additive = false; break; }
        const start = label_node[witness_i]; const target = label_node[witness_j];
        var parent_node: [MAX_NODES]i32 = @splat(-1);
        var parent_edge: [MAX_NODES]i32 = @splat(-1);
        var queue: [MAX_NODES]usize = @splat(0);
        var head: usize = 0; var tail: usize = 0;
        parent_node[start] = @intCast(start); queue[tail] = start; tail += 1;
        while (head < tail and parent_node[target] < 0) {
            const node = queue[head]; head += 1;
            for (0..edge_count) |e| {
                const u: usize = @intCast(edge_u[e]); const v: usize = @intCast(edge_v[e]);
                const neighbor = if (u == node) v else if (v == node) u else MAX_NODES;
                if (neighbor == MAX_NODES or parent_node[neighbor] >= 0) continue;
                parent_node[neighbor] = @intCast(node); parent_edge[neighbor] = @intCast(e);
                queue[tail] = neighbor; tail += 1;
            }
        }
        if (parent_node[target] < 0) { additive = false; break; }
        var reverse_nodes: [MAX_NODES]usize = @splat(0);
        var reverse_edges: [MAX_NODES]usize = @splat(0);
        var path_node_count: usize = 1; var path_edge_count: usize = 0;
        var current = target; reverse_nodes[0] = target;
        while (current != start) {
            reverse_edges[path_edge_count] = @intCast(parent_edge[current]); path_edge_count += 1;
            current = @intCast(parent_node[current]);
            reverse_nodes[path_node_count] = current; path_node_count += 1;
        }
        var path_nodes: [MAX_NODES]usize = @splat(0);
        var path_edges: [MAX_NODES]usize = @splat(0);
        for (0..path_node_count) |i| path_nodes[i] = reverse_nodes[path_node_count - 1 - i];
        for (0..path_edge_count) |i| path_edges[i] = reverse_edges[path_edge_count - 1 - i];
        var elapsed: i64 = 0;
        var attach_node: usize = MAX_NODES;
        var split_edge: usize = MAX_EDGES;
        var split_left: usize = MAX_NODES; var split_right: usize = MAX_NODES;
        var split_from_left: i64 = 0;
        for (0..path_node_count) |step| {
            if (attach_distance == elapsed) { attach_node = path_nodes[step]; break; }
            if (step == path_edge_count) break;
            const e = path_edges[step]; const weight = edge_w[e];
            if (elapsed < attach_distance and attach_distance < elapsed + weight) {
                split_edge = e; split_left = path_nodes[step]; split_right = path_nodes[step + 1];
                split_from_left = attach_distance - elapsed; break;
            }
            elapsed += weight;
        }
        if (attach_node == MAX_NODES and split_edge == MAX_EDGES) { additive = false; break; }
        if (split_edge != MAX_EDGES) {
            if (node_count >= MAX_NODES or edge_count >= MAX_EDGES) { additive = false; break; }
            const internal = node_count; node_count += 1;
            const whole = edge_w[split_edge];
            edge_u[split_edge] = @intCast(split_left); edge_v[split_edge] = @intCast(internal); edge_w[split_edge] = split_from_left;
            edge_u[edge_count] = @intCast(internal); edge_v[edge_count] = @intCast(split_right);
            edge_w[edge_count] = whole - split_from_left; edge_count += 1; attach_node = internal;
        }
        if (limb2 == 0) {
            if (label_mask[attach_node] != 0) { additive = false; break; }
            label_node[leaf] = attach_node; label_mask[attach_node] |= @as(u32, 1) << @intCast(leaf);
        } else {
            if (node_count >= MAX_NODES or edge_count >= MAX_EDGES) { additive = false; break; }
            const new_leaf = node_count; node_count += 1;
            label_node[leaf] = new_leaf; label_mask[new_leaf] = @as(u32, 1) << @intCast(leaf);
            edge_u[edge_count] = @intCast(attach_node); edge_v[edge_count] = @intCast(new_leaf);
            edge_w[edge_count] = limb2; edge_count += 1;
        }
    }
    if (!additive) return 0;

    var distances: [MAX_NODES]i64 = @splat(0);
    for (0..n) |i| for (i + 1..n) |j| {
        if (!tree_distance(node_count, edge_count, &edge_u, &edge_v, &edge_w,
                label_node[i], label_node[j], &distances) or distances[label_node[j]] != 2 * d[i * MAX_N + j]) return 0;
    };
    const full_mask = (@as(u32, 1) << @intCast(n)) - 1;
    var record_mask: [MAX_EDGES]i64 = @splat(0);
    var record_weight: [MAX_EDGES]i64 = @splat(0);
    for (0..edge_count) |e| {
        var seen = @as(u32, 1) << @intCast(edge_u[e]);
        var queue: [MAX_NODES]usize = @splat(0);
        var head: usize = 0; var tail: usize = 0;
        queue[tail] = @intCast(edge_u[e]); tail += 1;
        var mask: u32 = 0;
        while (head < tail) {
            const node = queue[head]; head += 1; mask |= label_mask[node];
            for (0..edge_count) |other| {
                if (other == e) continue;
                const u: usize = @intCast(edge_u[other]); const v: usize = @intCast(edge_v[other]);
                const neighbor = if (u == node) v else if (v == node) u else MAX_NODES;
                if (neighbor == MAX_NODES or (seen & (@as(u32, 1) << @intCast(neighbor))) != 0) continue;
                seen |= @as(u32, 1) << @intCast(neighbor); queue[tail] = neighbor; tail += 1;
            }
        }
        if (mask & 1 == 0) mask = full_mask ^ mask;
        record_mask[e] = @intCast(mask); record_weight[e] = edge_w[e];
    }
    for (1..edge_count) |i| {
        const mask = record_mask[i]; const weight = record_weight[i];
        var j = i;
        while (j > 0 and (record_mask[j - 1] > mask or (record_mask[j - 1] == mask and record_weight[j - 1] > weight))) {
            record_mask[j] = record_mask[j - 1]; record_weight[j] = record_weight[j - 1]; j -= 1;
        }
        record_mask[j] = mask; record_weight[j] = weight;
    }
    const output_bytes = 8 * (1 + 2 * edge_count);
    if (output_opt == null) return -2;
    const output = output_opt.?;
    if (capacity < output_bytes) return -2;
    var staged: [MAX_OUTPUT_BYTES]u8 = @splat(0);
    store_i64_le(&staged, 0, @intCast(edge_count));
    for (0..edge_count) |i| {
        store_i64_le(&staged, 8 * (1 + 2 * i), record_mask[i]);
        store_i64_le(&staged, 8 * (2 + 2 * i), record_weight[i]);
    }
    for (0..output_bytes) |byte| output[byte] = staged[byte];
    return @intCast(output_bytes);
}
