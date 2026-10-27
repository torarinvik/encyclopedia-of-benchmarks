#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 6, MAX_NODES = 10, MAX_EDGES = 9, MAX_OUTPUT_BYTES = 152 };

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

static int tree_distance(int node_count, int edge_count, const int *edge_u, const int *edge_v,
        const int64_t *edge_w, int start, int target, int64_t *distance) {
    int parent[MAX_NODES], queue[MAX_NODES];
    int head = 0, tail = 0;
    for (int i = 0; i < node_count; ++i) parent[i] = -1;
    parent[start] = start;
    distance[start] = 0;
    queue[tail++] = start;
    while (head < tail) {
        const int node = queue[head++];
        if (node == target) return 1;
        for (int e = 0; e < edge_count; ++e) {
            int neighbor = -1;
            if (edge_u[e] == node) neighbor = edge_v[e];
            else if (edge_v[e] == node) neighbor = edge_u[e];
            if (neighbor < 0 || parent[neighbor] != -1) continue;
            parent[neighbor] = node;
            distance[neighbor] = distance[node] + edge_w[e];
            queue[tail++] = neighbor;
        }
    }
    return 0;
}

int64_t phylogenetic_tree_from_distance_matrix(const int64_t *input, size_t length,
        uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || length > MAX_N * MAX_N + 2) return -1;
    const int64_t raw_n = input[0];
    if (raw_n < 2 || raw_n > MAX_N || length != (size_t)(1 + raw_n * raw_n)) return -1;
    const int n = (int)raw_n;
    int64_t distance_matrix[MAX_N * MAX_N] = {0};
    for (int i = 0; i < n; ++i) for (int j = 0; j < n; ++j) {
        const int64_t value = input[1 + i * n + j];
        if ((i == j && value != 0) || (i != j && (value < 1 || value > 32))) return -1;
        distance_matrix[i * MAX_N + j] = value;
    }
    for (int i = 0; i < n; ++i) for (int j = i + 1; j < n; ++j)
        if (distance_matrix[i * MAX_N + j] != distance_matrix[j * MAX_N + i]) return -1;

    int edge_u[MAX_EDGES] = {0}, edge_v[MAX_EDGES] = {0};
    int64_t edge_w[MAX_EDGES] = {0};
    int edge_count = 1;
    edge_u[0] = 0; edge_v[0] = 1; edge_w[0] = 2 * distance_matrix[1];
    int label_node[MAX_N] = {0, 1, 0, 0, 0, 0};
    unsigned label_mask[MAX_NODES] = {1u, 2u};
    int node_count = 2;
    int additive = 1;

    for (int leaf = 2; leaf < n && additive; ++leaf) {
        int64_t limb2 = INT64_MAX;
        for (int i = 0; i < leaf; ++i) for (int j = i + 1; j < leaf; ++j) {
            const int64_t candidate = distance_matrix[i * MAX_N + leaf] +
                distance_matrix[j * MAX_N + leaf] - distance_matrix[i * MAX_N + j];
            if (candidate < limb2) limb2 = candidate;
        }
        if (limb2 < 0) { additive = 0; break; }
        int witness_i = -1, witness_j = -1;
        int64_t attach_distance = 0;
        for (int i = 0; i < leaf && witness_i < 0; ++i) for (int j = i + 1; j < leaf; ++j) {
            const int64_t from_i = 2 * distance_matrix[i * MAX_N + leaf] - limb2;
            const int64_t from_j = 2 * distance_matrix[j * MAX_N + leaf] - limb2;
            if (from_i >= 0 && from_j >= 0 &&
                    2 * distance_matrix[i * MAX_N + j] == from_i + from_j) {
                witness_i = i; witness_j = j; attach_distance = from_i; break;
            }
        }
        if (witness_i < 0) { additive = 0; break; }

        const int start = label_node[witness_i], target = label_node[witness_j];
        int parent_node[MAX_NODES], parent_edge[MAX_NODES], queue[MAX_NODES];
        for (int i = 0; i < node_count; ++i) { parent_node[i] = -1; parent_edge[i] = -1; }
        int head = 0, tail = 0;
        parent_node[start] = start; queue[tail++] = start;
        while (head < tail && parent_node[target] < 0) {
            const int node = queue[head++];
            for (int e = 0; e < edge_count; ++e) {
                int neighbor = -1;
                if (edge_u[e] == node) neighbor = edge_v[e];
                else if (edge_v[e] == node) neighbor = edge_u[e];
                if (neighbor < 0 || parent_node[neighbor] >= 0) continue;
                parent_node[neighbor] = node; parent_edge[neighbor] = e; queue[tail++] = neighbor;
            }
        }
        if (parent_node[target] < 0) { additive = 0; break; }
        int reverse_nodes[MAX_NODES], reverse_edges[MAX_NODES];
        int path_node_count = 0, path_edge_count = 0, current = target;
        reverse_nodes[path_node_count++] = target;
        while (current != start) {
            reverse_edges[path_edge_count++] = parent_edge[current];
            current = parent_node[current];
            reverse_nodes[path_node_count++] = current;
        }
        int path_nodes[MAX_NODES], path_edges[MAX_NODES];
        for (int i = 0; i < path_node_count; ++i) path_nodes[i] = reverse_nodes[path_node_count - 1 - i];
        for (int i = 0; i < path_edge_count; ++i) path_edges[i] = reverse_edges[path_edge_count - 1 - i];

        int attach_node = -1, split_edge = -1, split_left = -1, split_right = -1;
        int64_t elapsed = 0, split_from_left = 0;
        for (int step = 0; step < path_node_count; ++step) {
            if (attach_distance == elapsed) { attach_node = path_nodes[step]; break; }
            if (step == path_edge_count) break;
            const int e = path_edges[step];
            const int64_t weight = edge_w[e];
            if (elapsed < attach_distance && attach_distance < elapsed + weight) {
                split_edge = e; split_left = path_nodes[step]; split_right = path_nodes[step + 1];
                split_from_left = attach_distance - elapsed; break;
            }
            elapsed += weight;
        }
        if (attach_node < 0 && split_edge < 0) { additive = 0; break; }
        if (split_edge >= 0) {
            if (node_count >= MAX_NODES || edge_count >= MAX_EDGES) { additive = 0; break; }
            const int internal = node_count++;
            const int64_t whole = edge_w[split_edge];
            edge_u[split_edge] = split_left; edge_v[split_edge] = internal; edge_w[split_edge] = split_from_left;
            edge_u[edge_count] = internal; edge_v[edge_count] = split_right; edge_w[edge_count] = whole - split_from_left;
            ++edge_count;
            attach_node = internal;
        }
        if (limb2 == 0) {
            if (label_mask[attach_node] != 0) { additive = 0; break; }
            label_node[leaf] = attach_node;
            label_mask[attach_node] |= 1u << leaf;
        } else {
            if (node_count >= MAX_NODES || edge_count >= MAX_EDGES) { additive = 0; break; }
            const int new_leaf = node_count++;
            label_node[leaf] = new_leaf;
            label_mask[new_leaf] = 1u << leaf;
            edge_u[edge_count] = attach_node; edge_v[edge_count] = new_leaf; edge_w[edge_count] = limb2;
            ++edge_count;
        }
    }

    if (!additive) return 0;
    int64_t path_distance[MAX_NODES] = {0};
    for (int i = 0; i < n; ++i) for (int j = i + 1; j < n; ++j) {
        if (!tree_distance(node_count, edge_count, edge_u, edge_v, edge_w,
                label_node[i], label_node[j], path_distance) ||
                path_distance[label_node[j]] != 2 * distance_matrix[i * MAX_N + j]) return 0;
    }

    int64_t record_mask[MAX_EDGES], record_weight[MAX_EDGES];
    const unsigned full_mask = (1u << n) - 1u;
    for (int e = 0; e < edge_count; ++e) {
        unsigned seen_nodes = 1u << edge_u[e];
        int cut_queue[MAX_NODES], cut_head = 0, cut_tail = 0;
        cut_queue[cut_tail++] = edge_u[e];
        unsigned mask = 0;
        while (cut_head < cut_tail) {
            const int node = cut_queue[cut_head++];
            mask |= label_mask[node];
            for (int other = 0; other < edge_count; ++other) {
                if (other == e) continue;
                int neighbor = -1;
                if (edge_u[other] == node) neighbor = edge_v[other];
                else if (edge_v[other] == node) neighbor = edge_u[other];
                if (neighbor < 0 || (seen_nodes & (1u << neighbor))) continue;
                seen_nodes |= 1u << neighbor; cut_queue[cut_tail++] = neighbor;
            }
        }
        if ((mask & 1u) == 0) mask = full_mask ^ mask;
        record_mask[e] = mask; record_weight[e] = edge_w[e];
    }
    for (int i = 1; i < edge_count; ++i) {
        const int64_t mask = record_mask[i], weight = record_weight[i];
        int j = i;
        while (j > 0 && (record_mask[j - 1] > mask ||
                (record_mask[j - 1] == mask && record_weight[j - 1] > weight))) {
            record_mask[j] = record_mask[j - 1]; record_weight[j] = record_weight[j - 1]; --j;
        }
        record_mask[j] = mask; record_weight[j] = weight;
    }
    const size_t output_bytes = 8u * (1u + 2u * (size_t)edge_count);
    if (output == NULL) return -2;
    if (capacity < output_bytes) return -2;
    uint8_t staged[MAX_OUTPUT_BYTES] = {0};
    store_i64_le(staged, 0, edge_count);
    for (int i = 0; i < edge_count; ++i) {
        store_i64_le(staged, 8u * (1u + 2u * (size_t)i), record_mask[i]);
        store_i64_le(staged, 8u * (2u + 2u * (size_t)i), record_weight[i]);
    }
    for (size_t byte = 0; byte < output_bytes; ++byte) output[byte] = staged[byte];
    return (int64_t)output_bytes;
}
