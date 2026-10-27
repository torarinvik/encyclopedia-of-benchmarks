module phylogenetic_tree_from_distance_matrix;

const usz MAX_N = 6;
const usz MAX_NODES = 10;
const usz MAX_EDGES = 9;
const usz MAX_OUTPUT_BYTES = 152;

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) { output[offset + byte] = (char)(bits & 255); bits >>= 8; }
}

fn bool tree_distance(int node_count, int edge_count, int* edge_u, int* edge_v,
        long* edge_w, int start, int target, long* distances) {
    int[MAX_NODES] parent = zeroed, queue = zeroed;
    for (int i = 0; i < node_count; i += 1) parent[i.usz()] = -1;
    int head = 0, tail = 0;
    parent[start.usz()] = start; distances[start.usz()] = 0; queue[tail.usz()] = start; tail += 1;
    while (head < tail) {
        int node = queue[head.usz()]; head += 1;
        if (node == target) return true;
        for (int e = 0; e < edge_count; e += 1) {
            int neighbor = if edge_u[e.usz()] == node: edge_v[e.usz()] else if edge_v[e.usz()] == node: edge_u[e.usz()] else: -1;
            if (neighbor < 0 || parent[neighbor.usz()] != -1) continue;
            parent[neighbor.usz()] = node;
            distances[neighbor.usz()] = distances[node.usz()] + edge_w[e.usz()];
            queue[tail.usz()] = neighbor; tail += 1;
        }
    }
    return false;
}

long phylogenetic_tree_from_distance_matrix(long* input, usz length, char* output, usz capacity)
        @export("phylogenetic_tree_from_distance_matrix") {
    if (input == null || length < 1 || length > MAX_N * MAX_N + 2) return -1;
    long raw_n = input[0];
    if (raw_n < 2 || raw_n > MAX_N.long() || length != (1 + raw_n * raw_n).usz()) return -1;
    int n = raw_n.int();
    long[MAX_N * MAX_N] d = zeroed;
    for (int i = 0; i < n; i += 1) for (int j = 0; j < n; j += 1) {
        long value = input[(1 + i * n + j).usz()];
        if ((i == j && value != 0) || (i != j && (value < 1 || value > 32))) return -1;
        d[(i * MAX_N + j).usz()] = value;
    }
    for (int i = 0; i < n; i += 1) for (int j = i + 1; j < n; j += 1)
        if (d[(i * MAX_N + j).usz()] != d[(j * MAX_N + i).usz()]) return -1;

    int[MAX_EDGES] edge_u = zeroed, edge_v = zeroed;
    long[MAX_EDGES] edge_w = zeroed;
    int edge_count = 1;
    edge_u[0] = 0; edge_v[0] = 1; edge_w[0] = 2 * d[1];
    int[MAX_N] label_node = {0, 1, 0, 0, 0, 0};
    uint[MAX_NODES] label_mask = {1, 2};
    int node_count = 2;
    bool additive = true;
    for (int leaf = 2; leaf < n; leaf += 1) {
        if (!additive) break;
        long limb2 = 0x7FFFFFFFFFFFFFFF;
        for (int i = 0; i < leaf; i += 1) for (int j = i + 1; j < leaf; j += 1) {
            long candidate = d[(i * MAX_N + leaf).usz()] + d[(j * MAX_N + leaf).usz()] - d[(i * MAX_N + j).usz()];
            if (candidate < limb2) limb2 = candidate;
        }
        if (limb2 < 0) { additive = false; break; }
        int witness_i = -1, witness_j = -1;
        long attach_distance = 0;
        for (int i = 0; i < leaf && witness_i < 0; i += 1) for (int j = i + 1; j < leaf; j += 1) {
            long from_i = 2 * d[(i * MAX_N + leaf).usz()] - limb2;
            long from_j = 2 * d[(j * MAX_N + leaf).usz()] - limb2;
            if (from_i >= 0 && from_j >= 0 && 2 * d[(i * MAX_N + j).usz()] == from_i + from_j) {
                witness_i = i; witness_j = j; attach_distance = from_i; break;
            }
        }
        if (witness_i < 0) { additive = false; break; }
        int start = label_node[witness_i.usz()], target = label_node[witness_j.usz()];
        int[MAX_NODES] parent_node = zeroed, parent_edge = zeroed, queue = zeroed;
        for (int i = 0; i < node_count; i += 1) { parent_node[i.usz()] = -1; parent_edge[i.usz()] = -1; }
        int head = 0, tail = 0;
        parent_node[start.usz()] = start; queue[tail.usz()] = start; tail += 1;
        while (head < tail && parent_node[target.usz()] < 0) {
            int node = queue[head.usz()]; head += 1;
            for (int e = 0; e < edge_count; e += 1) {
                int neighbor = if edge_u[e.usz()] == node: edge_v[e.usz()] else if edge_v[e.usz()] == node: edge_u[e.usz()] else: -1;
                if (neighbor < 0 || parent_node[neighbor.usz()] >= 0) continue;
                parent_node[neighbor.usz()] = node; parent_edge[neighbor.usz()] = e; queue[tail.usz()] = neighbor; tail += 1;
            }
        }
        if (parent_node[target.usz()] < 0) { additive = false; break; }
        int[MAX_NODES] reverse_nodes = zeroed, reverse_edges = zeroed;
        int path_node_count = 1, path_edge_count = 0, current = target;
        reverse_nodes[0] = target;
        while (current != start) {
            reverse_edges[path_edge_count.usz()] = parent_edge[current.usz()]; path_edge_count += 1;
            current = parent_node[current.usz()]; reverse_nodes[path_node_count.usz()] = current; path_node_count += 1;
        }
        int[MAX_NODES] path_nodes = zeroed, path_edges = zeroed;
        for (int i = 0; i < path_node_count; i += 1) path_nodes[i.usz()] = reverse_nodes[(path_node_count - 1 - i).usz()];
        for (int i = 0; i < path_edge_count; i += 1) path_edges[i.usz()] = reverse_edges[(path_edge_count - 1 - i).usz()];
        long elapsed = 0;
        int attach_node = -1, split_edge = -1, split_left = -1, split_right = -1;
        long split_from_left = 0;
        for (int step = 0; step < path_node_count; step += 1) {
            if (attach_distance == elapsed) { attach_node = path_nodes[step.usz()]; break; }
            if (step == path_edge_count) break;
            int e = path_edges[step.usz()];
            long weight = edge_w[e.usz()];
            if (elapsed < attach_distance && attach_distance < elapsed + weight) {
                split_edge = e; split_left = path_nodes[step.usz()]; split_right = path_nodes[(step + 1).usz()];
                split_from_left = attach_distance - elapsed; break;
            }
            elapsed += weight;
        }
        if (attach_node < 0 && split_edge < 0) { additive = false; break; }
        if (split_edge >= 0) {
            if (node_count >= MAX_NODES.int() || edge_count >= MAX_EDGES.int()) { additive = false; break; }
            int internal = node_count; node_count += 1;
            long whole = edge_w[split_edge.usz()];
            edge_u[split_edge.usz()] = split_left; edge_v[split_edge.usz()] = internal; edge_w[split_edge.usz()] = split_from_left;
            edge_u[edge_count.usz()] = internal; edge_v[edge_count.usz()] = split_right;
            edge_w[edge_count.usz()] = whole - split_from_left; edge_count += 1; attach_node = internal;
        }
        if (limb2 == 0) {
            if (label_mask[attach_node.usz()] != 0) { additive = false; break; }
            label_node[leaf.usz()] = attach_node; label_mask[attach_node.usz()] |= 1u << leaf;
        } else {
            if (node_count >= MAX_NODES.int() || edge_count >= MAX_EDGES.int()) { additive = false; break; }
            int new_leaf = node_count; node_count += 1;
            label_node[leaf.usz()] = new_leaf; label_mask[new_leaf.usz()] = 1u << leaf;
            edge_u[edge_count.usz()] = attach_node; edge_v[edge_count.usz()] = new_leaf;
            edge_w[edge_count.usz()] = limb2; edge_count += 1;
        }
    }
    if (!additive) return 0;
    long[MAX_NODES] distances = zeroed;
    for (int i = 0; i < n; i += 1) for (int j = i + 1; j < n; j += 1) {
        if (!tree_distance(node_count, edge_count, &edge_u[0], &edge_v[0], &edge_w[0],
                label_node[i.usz()], label_node[j.usz()], &distances[0]) ||
                distances[label_node[j.usz()]] != 2 * d[(i * MAX_N + j).usz()]) return 0;
    }
    uint full_mask = (1u << n) - 1u;
    long[MAX_EDGES] record_mask = zeroed, record_weight = zeroed;
    for (int e = 0; e < edge_count; e += 1) {
        uint seen = 1u << edge_u[e.usz()];
        int[MAX_NODES] cut_queue = zeroed;
        int head = 0, tail = 0; cut_queue[tail.usz()] = edge_u[e.usz()]; tail += 1;
        uint mask = 0;
        while (head < tail) {
            int node = cut_queue[head.usz()]; head += 1; mask |= label_mask[node.usz()];
            for (int other = 0; other < edge_count; other += 1) {
                if (other == e) continue;
                int neighbor = if edge_u[other.usz()] == node: edge_v[other.usz()] else if edge_v[other.usz()] == node: edge_u[other.usz()] else: -1;
                if (neighbor < 0 || (seen & (1u << neighbor)) != 0) continue;
                seen |= 1u << neighbor; cut_queue[tail.usz()] = neighbor; tail += 1;
            }
        }
        if ((mask & 1u) == 0) mask = full_mask ^ mask;
        record_mask[e.usz()] = mask.long(); record_weight[e.usz()] = edge_w[e.usz()];
    }
    for (int i = 1; i < edge_count; i += 1) {
        long mask = record_mask[i.usz()], weight = record_weight[i.usz()];
        int j = i;
        while (j > 0 && (record_mask[(j - 1).usz()] > mask ||
                (record_mask[(j - 1).usz()] == mask && record_weight[(j - 1).usz()] > weight))) {
            record_mask[j.usz()] = record_mask[(j - 1).usz()]; record_weight[j.usz()] = record_weight[(j - 1).usz()]; j -= 1;
        }
        record_mask[j.usz()] = mask; record_weight[j.usz()] = weight;
    }
    usz output_bytes = 8 * (1 + 2 * edge_count.usz());
    if (output == null || capacity < output_bytes) return -2;
    char[MAX_OUTPUT_BYTES] staged = zeroed;
    store_i64_le(&staged[0], 0, edge_count.long());
    for (int i = 0; i < edge_count; i += 1) {
        store_i64_le(&staged[0], 8 * (1 + 2 * i).usz(), record_mask[i.usz()]);
        store_i64_le(&staged[0], 8 * (2 + 2 * i).usz(), record_weight[i.usz()]);
    }
    for (usz byte = 0; byte < output_bytes; byte += 1) output[byte] = staged[byte];
    return output_bytes.long();
}
