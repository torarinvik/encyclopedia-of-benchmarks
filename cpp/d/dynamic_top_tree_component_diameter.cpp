// Fixed-tree diameter updates using a rake/compress cluster hierarchy.
#include <cstddef>
#include <cstdint>

namespace {
constexpr int max_vertices = 16, max_operations = 32, max_edges = 15;
constexpr int max_nodes = 75, max_input = 143;
constexpr std::int64_t max_weight = 1000;
enum { edge_base = 0, edge_compress = 1, rake_zero = 2, rake_merge = 3, rake_branch = 4 };

struct Node {
    std::int16_t kind, a, b, c, parent, endpoint0, endpoint1, pivot, edge_id;
    std::int64_t length, far0, far1, diameter, best1, best2;
};

int find_root(int parent[max_vertices], int vertex) {
    while (parent[vertex] != vertex) {
        parent[vertex] = parent[parent[vertex]];
        vertex = parent[vertex];
    }
    return vertex;
}

std::int64_t far_at(const Node nodes[max_nodes], int node_id, int vertex) {
    const Node &node = nodes[node_id];
    return node.endpoint0 == vertex ? node.far0 : node.far1;
}

void recalculate(Node nodes[max_nodes], int node_id, const std::int64_t weights[max_edges]) {
    Node &node = nodes[node_id];
    if (node.kind == edge_base) {
        const auto weight = weights[node.edge_id];
        node.length = node.far0 = node.far1 = node.diameter = weight;
    } else if (node.kind == rake_zero) {
        node.best1 = node.best2 = node.diameter = 0;
    } else if (node.kind == rake_merge) {
        const Node &left = nodes[node.a], &right = nodes[node.b];
        std::int64_t first = 0, second = 0;
        const std::int64_t arms[4] = {left.best1, left.best2, right.best1, right.best2};
        for (auto arm : arms) {
            if (arm >= first) { second = first; first = arm; }
            else if (arm > second) second = arm;
        }
        node.best1 = first; node.best2 = second;
        node.diameter = left.diameter > right.diameter ? left.diameter : right.diameter;
        if (left.best1 + right.best1 > node.diameter) node.diameter = left.best1 + right.best1;
    } else if (node.kind == rake_branch) {
        const Node &edge = nodes[node.a], &local = nodes[node.b];
        const auto center_far = far_at(nodes, node.a, node.endpoint0);
        const auto pivot_far = far_at(nodes, node.a, node.pivot);
        node.best1 = center_far > edge.length + local.best1 ? center_far : edge.length + local.best1;
        node.best2 = 0;
        node.diameter = edge.diameter > local.diameter ? edge.diameter : local.diameter;
        if (pivot_far + local.best1 > node.diameter) node.diameter = pivot_far + local.best1;
    } else {
        const Node &first = nodes[node.a], &second = nodes[node.b], &local = nodes[node.c];
        const int y = node.endpoint0, z = node.endpoint1, x = node.pivot;
        const auto first_y = far_at(nodes, node.a, y), first_x = far_at(nodes, node.a, x);
        const auto second_x = far_at(nodes, node.b, x), second_z = far_at(nodes, node.b, z);
        node.length = first.length + second.length;
        const auto from_y = first.length + (second_x > local.best1 ? second_x : local.best1);
        const auto from_z = second.length + (first_x > local.best1 ? first_x : local.best1);
        node.far0 = first_y > from_y ? first_y : from_y;
        node.far1 = second_z > from_z ? second_z : from_z;
        node.diameter = first.diameter > second.diameter ? first.diameter : second.diameter;
        if (local.diameter > node.diameter) node.diameter = local.diameter;
        if (first_x + second_x > node.diameter) node.diameter = first_x + second_x;
        if (first_x + local.best1 > node.diameter) node.diameter = first_x + local.best1;
        if (second_x + local.best1 > node.diameter) node.diameter = second_x + local.best1;
    }
}

int append_node(Node nodes[max_nodes], int &count, int kind,
                const std::int64_t weights[max_edges], int a, int b, int c,
                int endpoint0, int endpoint1, int pivot, int edge_id) {
    if (count >= max_nodes) return -1;
    const int id = count++;
    Node &node = nodes[id];
    node.kind = static_cast<std::int16_t>(kind);
    node.a = static_cast<std::int16_t>(a); node.b = static_cast<std::int16_t>(b); node.c = static_cast<std::int16_t>(c);
    node.parent = -1;
    node.endpoint0 = static_cast<std::int16_t>(endpoint0); node.endpoint1 = static_cast<std::int16_t>(endpoint1);
    node.pivot = static_cast<std::int16_t>(pivot); node.edge_id = static_cast<std::int16_t>(edge_id);
    node.length = node.far0 = node.far1 = node.diameter = node.best1 = node.best2 = 0;
    if (a >= 0) nodes[a].parent = static_cast<std::int16_t>(id);
    if (b >= 0) nodes[b].parent = static_cast<std::int16_t>(id);
    if (c >= 0) nodes[c].parent = static_cast<std::int16_t>(id);
    recalculate(nodes, id, weights);
    return id;
}

int make_rake(Node nodes[max_nodes], int &node_count,
              const std::int64_t weights[max_edges], int base,
              const std::int16_t branch_ids[max_vertices], int branch_count) {
    std::int16_t level[max_vertices + 1], next[max_vertices + 1];
    int count = 1;
    level[0] = static_cast<std::int16_t>(base);
    for (int i = 0; i < branch_count; ++i) level[count++] = branch_ids[i];
    while (count > 1) {
        int next_count = 0;
        for (int i = 0; i < count; i += 2) {
            if (i + 1 == count) next[next_count++] = level[i];
            else {
                const int merged = append_node(nodes, node_count, rake_merge, weights,
                                               level[i], level[i + 1], -1, -1, -1, -1, -1);
                if (merged < 0) return -1;
                next[next_count++] = static_cast<std::int16_t>(merged);
            }
        }
        for (int i = 0; i < next_count; ++i) level[i] = next[i];
        count = next_count;
    }
    return level[0];
}

int neighbor_count(const bool adjacency[max_vertices][max_vertices],
                   const bool active[max_vertices], int n, int vertex, int output[2]) {
    int count = 0;
    for (int other = 0; other < n; ++other) if (active[other] && adjacency[vertex][other]) {
        if (count < 2) output[count] = other;
        ++count;
    }
    return count;
}
}

extern "C" std::int64_t dynamic_top_tree_component_diameter(
    const std::int64_t *input, std::size_t length, std::uint8_t *output, std::size_t capacity) {
    if (input == nullptr || length < 2 || length > max_input) return -1;
    const auto n_value = input[0], q_value = input[1];
    if (n_value < 1 || n_value > max_vertices || q_value < 0 || q_value > max_operations) return -1;
    const int n = static_cast<int>(n_value), q = static_cast<int>(q_value);
    const int edge_end = 2 + 3 * (n - 1);
    if (length != static_cast<std::size_t>(edge_end + 3 * q)) return -1;

    int edge_u[max_edges], edge_v[max_edges], dsu[max_vertices];
    std::int64_t weights[max_edges]{};
    for (int i = 0; i < n; ++i) dsu[i] = i;
    for (int edge_id = 0; edge_id < n - 1; ++edge_id) {
        const int offset = 2 + 3 * edge_id;
        const auto u_value = input[offset], v_value = input[offset + 1], weight = input[offset + 2];
        if (u_value < 0 || u_value >= n || v_value < 0 || v_value >= n || u_value == v_value || weight < 0 || weight > max_weight) return -1;
        const int u = static_cast<int>(u_value), v = static_cast<int>(v_value);
        const int ru = find_root(dsu, u), rv = find_root(dsu, v);
        if (ru == rv) return -1;
        dsu[ru] = rv;
        edge_u[edge_id] = u; edge_v[edge_id] = v; weights[edge_id] = weight;
    }
    for (int vertex = 1; vertex < n; ++vertex) if (find_root(dsu, vertex) != find_root(dsu, 0)) return -1;

    int op_code[max_operations], op_edge[max_operations], op_value[max_operations];
    int query_count = 0;
    for (int op = 0; op < q; ++op) {
        const int offset = edge_end + 3 * op;
        const auto opcode = input[offset], edge_id = input[offset + 1], value = input[offset + 2];
        if (opcode == 0) {
            if (edge_id < 0 || edge_id >= n - 1 || value < 0 || value > max_weight) return -1;
        } else if (opcode == 1) {
            if (edge_id != 0 || value != 0) return -1;
            ++query_count;
        } else return -1;
        op_code[op] = static_cast<int>(opcode); op_edge[op] = static_cast<int>(edge_id); op_value[op] = static_cast<int>(value);
    }
    const std::size_t output_bytes = static_cast<std::size_t>(query_count) * 8;
    if (output_bytes > 0 && (output == nullptr || capacity < output_bytes)) return -2;

    Node nodes[max_nodes];
    int node_count = 0, base_rake[max_vertices], base_edge[max_edges];
    bool adjacency[max_vertices][max_vertices]{};
    bool active[max_vertices]{};
    std::int16_t edge_cluster[max_vertices][max_vertices];
    std::int16_t branches[max_vertices][max_vertices];
    int branch_count[max_vertices]{};
    for (int u = 0; u < max_vertices; ++u) for (int v = 0; v < max_vertices; ++v) edge_cluster[u][v] = -1;
    for (int vertex = 0; vertex < n; ++vertex) {
        active[vertex] = true;
        base_rake[vertex] = append_node(nodes, node_count, rake_zero, weights, -1, -1, -1, -1, -1, -1, -1);
        if (base_rake[vertex] < 0) return -1;
    }
    for (int edge_id = 0; edge_id < n - 1; ++edge_id) {
        const int u = edge_u[edge_id], v = edge_v[edge_id];
        const int cluster = append_node(nodes, node_count, edge_base, weights, -1, -1, -1, u, v, -1, edge_id);
        if (cluster < 0) return -1;
        base_edge[edge_id] = cluster;
        adjacency[u][v] = adjacency[v][u] = true;
        edge_cluster[u][v] = edge_cluster[v][u] = static_cast<std::int16_t>(cluster);
    }

    int active_count = n;
    while (active_count > 1) {
        if (active_count == 2) {
            int pair[2], found = 0;
            for (int vertex = 0; vertex < n; ++vertex) if (active[vertex]) pair[found++] = vertex;
            const int x = pair[0], y = pair[1];
            const int local = make_rake(nodes, node_count, weights, base_rake[x], branches[x], branch_count[x]);
            if (local < 0) return -1;
            const int branch = append_node(nodes, node_count, rake_branch, weights, edge_cluster[x][y], local, -1, y, -1, x, -1);
            if (branch < 0) return -1;
            branches[y][branch_count[y]++] = static_cast<std::int16_t>(branch);
            adjacency[x][y] = adjacency[y][x] = false; active[x] = false; --active_count;
            break;
        }
        int leaves[max_vertices], leaf_neighbor[max_vertices], leaf_count = 0;
        for (int vertex = 0; vertex < n; ++vertex) if (active[vertex]) {
            int adjacent[2];
            if (neighbor_count(adjacency, active, n, vertex, adjacent) == 1) {
                leaves[leaf_count] = vertex; leaf_neighbor[leaf_count++] = adjacent[0];
            }
        }
        for (int i = 0; i < leaf_count; ++i) {
            const int x = leaves[i], y = leaf_neighbor[i];
            const int local = make_rake(nodes, node_count, weights, base_rake[x], branches[x], branch_count[x]);
            if (local < 0) return -1;
            const int branch = append_node(nodes, node_count, rake_branch, weights, edge_cluster[x][y], local, -1, y, -1, x, -1);
            if (branch < 0 || branch_count[y] >= max_vertices) return -1;
            branches[y][branch_count[y]++] = static_cast<std::int16_t>(branch);
        }
        for (int i = 0; i < leaf_count; ++i) {
            const int x = leaves[i], y = leaf_neighbor[i];
            adjacency[x][y] = adjacency[y][x] = false;
            edge_cluster[x][y] = edge_cluster[y][x] = -1;
            active[x] = false; --active_count;
        }
        if (active_count <= 1) break;

        bool chosen[max_vertices]{};
        int compress_vertices[max_vertices], compress_count = 0;
        for (int x = 0; x < n; ++x) if (active[x]) {
            int adjacent[2];
            if (neighbor_count(adjacency, active, n, x, adjacent) != 2) continue;
            if (!chosen[adjacent[0]] && !chosen[adjacent[1]]) { chosen[x] = true; compress_vertices[compress_count++] = x; }
        }
        int pending_x[max_vertices], pending_y[max_vertices], pending_z[max_vertices], pending_cluster[max_vertices];
        for (int i = 0; i < compress_count; ++i) {
            const int x = compress_vertices[i]; int adjacent[2];
            neighbor_count(adjacency, active, n, x, adjacent);
            const int y = adjacent[0], z = adjacent[1];
            const int local = make_rake(nodes, node_count, weights, base_rake[x], branches[x], branch_count[x]);
            if (local < 0) return -1;
            const int compressed = append_node(nodes, node_count, edge_compress, weights,
                edge_cluster[y][x], edge_cluster[x][z], local, y, z, x, -1);
            if (compressed < 0) return -1;
            pending_x[i] = x; pending_y[i] = y; pending_z[i] = z; pending_cluster[i] = compressed;
        }
        for (int i = 0; i < compress_count; ++i) {
            const int x = pending_x[i], y = pending_y[i], z = pending_z[i];
            adjacency[y][x] = adjacency[x][y] = adjacency[x][z] = adjacency[z][x] = false;
            edge_cluster[y][x] = edge_cluster[x][y] = edge_cluster[x][z] = edge_cluster[z][x] = -1;
            active[x] = false; --active_count;
        }
        for (int i = 0; i < compress_count; ++i) {
            const int y = pending_y[i], z = pending_z[i];
            adjacency[y][z] = adjacency[z][y] = true;
            edge_cluster[y][z] = edge_cluster[z][y] = static_cast<std::int16_t>(pending_cluster[i]);
        }
    }
    int root_vertex = 0;
    while (!active[root_vertex]) ++root_vertex;
    const int root = make_rake(nodes, node_count, weights, base_rake[root_vertex], branches[root_vertex], branch_count[root_vertex]);
    std::int64_t staged[max_operations];
    int staged_count = 0;
    for (int op = 0; op < q; ++op) {
        if (op_code[op] == 0) {
            const int edge_id = op_edge[op]; weights[edge_id] = op_value[op];
            int node_id = base_edge[edge_id];
            recalculate(nodes, node_id, weights);
            int ancestor = nodes[node_id].parent;
            while (ancestor >= 0) { recalculate(nodes, ancestor, weights); ancestor = nodes[ancestor].parent; }
        } else staged[staged_count++] = nodes[root].diameter;
    }
    for (int i = 0; i < staged_count; ++i) {
        const std::uint64_t bits = static_cast<std::uint64_t>(staged[i]);
        for (int byte = 0; byte < 8; ++byte) output[8 * i + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
    }
    return static_cast<std::int64_t>(output_bytes);
}
