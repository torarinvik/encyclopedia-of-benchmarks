#include <stddef.h>
#include <stdint.h>

enum { EP_MAX_N = 20, EP_MAX_M = 190, EP_MAX_INPUT = 383, EP_INF = 1000 };
typedef struct {
    int center;
    int radius;
    uint8_t members[EP_MAX_N];
    uint8_t tree[EP_MAX_M];
} EpCluster;

static void ep_bfs_distances(int n, const uint8_t adjacent[EP_MAX_N][EP_MAX_N],
                             int source, int distance[EP_MAX_N]) {
    int queue[EP_MAX_N];
    int head = 0, tail = 0;
    for (int v = 0; v < n; ++v) distance[v] = EP_INF;
    distance[source] = 0;
    queue[tail++] = source;
    while (head < tail) {
        const int vertex = queue[head++];
        for (int neighbor = 0; neighbor < n; ++neighbor) {
            if (adjacent[vertex][neighbor] && distance[neighbor] == EP_INF) {
                distance[neighbor] = distance[vertex] + 1;
                queue[tail++] = neighbor;
            }
        }
    }
}

static int ep_edge_id(int a, int b, const int edge_index[EP_MAX_N][EP_MAX_N]) {
    return a < b ? edge_index[a][b] : edge_index[b][a];
}

static int ep_bfs_tree(int n, const uint8_t adjacent[EP_MAX_N][EP_MAX_N],
                       const int edge_index[EP_MAX_N][EP_MAX_N],
                       const uint8_t members[EP_MAX_N], int root,
                       uint8_t tree[EP_MAX_M], int distance[EP_MAX_N]) {
    int parent[EP_MAX_N], queue[EP_MAX_N];
    int head = 0, tail = 0, radius = 0;
    for (int v = 0; v < n; ++v) { distance[v] = EP_INF; parent[v] = -1; }
    distance[root] = 0;
    queue[tail++] = root;
    while (head < tail) {
        const int vertex = queue[head++];
        for (int neighbor = 0; neighbor < n; ++neighbor) {
            if (members[neighbor] && adjacent[vertex][neighbor] && distance[neighbor] == EP_INF) {
                distance[neighbor] = distance[vertex] + 1;
                parent[neighbor] = vertex;
                queue[tail++] = neighbor;
            }
        }
    }
    for (int vertex = 0; vertex < n; ++vertex) {
        if (!members[vertex]) continue;
        if (distance[vertex] > radius) radius = distance[vertex];
        if (vertex != root) {
            const int edge = ep_edge_id(vertex, parent[vertex], edge_index);
            if (edge >= 0) tree[edge] = 1;
        }
    }
    return radius;
}

static int ep_set_distance(int n, const uint8_t left[EP_MAX_N],
                           const uint8_t right[EP_MAX_N],
                           const int distances[EP_MAX_N][EP_MAX_N]) {
    int best = EP_INF;
    for (int u = 0; u < n; ++u) if (left[u])
        for (int v = 0; v < n; ++v) if (right[v] && distances[u][v] < best)
            best = distances[u][v];
    return best;
}

static int ep_cluster_before(const EpCluster *left, const EpCluster *right, int n) {
    if (left->center != right->center) return left->center < right->center;
    int li = 0, ri = 0;
    while (li < n && ri < n) {
        while (li < n && !left->members[li]) ++li;
        while (ri < n && !right->members[ri]) ++ri;
        if (li == n || ri == n) break;
        if (li != ri) return li < ri;
        ++li; ++ri;
    }
    while (li < n && !left->members[li]) ++li;
    while (ri < n && !right->members[ri]) ++ri;
    return li == n && ri != n;
}

static void ep_connector(int n, const uint8_t adjacent[EP_MAX_N][EP_MAX_N],
                         const int edge_index[EP_MAX_N][EP_MAX_N],
                         const uint8_t left[EP_MAX_N], const uint8_t right[EP_MAX_N],
                         uint8_t path_edges[EP_MAX_M]) {
    int best_distance = EP_INF, best_length = 0;
    int best_path[EP_MAX_N];
    int have_best = 0;
    for (int source = 0; source < n; ++source) {
        if (!left[source]) continue;
        int distance[EP_MAX_N], parent[EP_MAX_N], queue[EP_MAX_N];
        int head = 0, tail = 0;
        for (int v = 0; v < n; ++v) { distance[v] = EP_INF; parent[v] = -1; }
        distance[source] = 0;
        queue[tail++] = source;
        while (head < tail) {
            const int vertex = queue[head++];
            for (int neighbor = 0; neighbor < n; ++neighbor) {
                if (adjacent[vertex][neighbor] && distance[neighbor] == EP_INF) {
                    distance[neighbor] = distance[vertex] + 1;
                    parent[neighbor] = vertex;
                    queue[tail++] = neighbor;
                }
            }
        }
        for (int target = 0; target < n; ++target) {
            if (!right[target] || distance[target] == EP_INF || distance[target] > best_distance) continue;
            int reverse_path[EP_MAX_N], candidate[EP_MAX_N], length = 0;
            int vertex = target;
            while (vertex >= 0 && length < EP_MAX_N) {
                reverse_path[length++] = vertex;
                if (vertex == source) break;
                vertex = parent[vertex];
            }
            if (length == 0 || reverse_path[length - 1] != source) continue;
            for (int i = 0; i < length; ++i) candidate[i] = reverse_path[length - 1 - i];
            int earlier = !have_best || distance[target] < best_distance;
            if (!earlier && distance[target] == best_distance) {
                for (int i = 0; i < length; ++i) {
                    if (candidate[i] != best_path[i]) {
                        earlier = candidate[i] < best_path[i];
                        break;
                    }
                }
            }
            if (earlier) {
                have_best = 1;
                best_distance = distance[target];
                best_length = length;
                for (int i = 0; i < length; ++i) best_path[i] = candidate[i];
            }
        }
    }
    for (int i = 1; i < best_length; ++i) {
        const int edge = ep_edge_id(best_path[i - 1], best_path[i], edge_index);
        if (edge >= 0) path_edges[edge] = 1;
    }
}

static int ep_sigma(int n) {
    int sigma = 1;
    while (sigma * sigma * sigma * sigma < n) ++sigma;
    return sigma;
}

static void ep_supercluster(int n, int m, const uint8_t adjacent[EP_MAX_N][EP_MAX_N],
                            const int edge_index[EP_MAX_N][EP_MAX_N],
                            const int distances[EP_MAX_N][EP_MAX_N],
                            const EpCluster *input, int input_count, int sigma, int delta,
                            EpCluster output[EP_MAX_N], int *output_count,
                            uint8_t chosen[EP_MAX_M]) {
    uint8_t active[EP_MAX_N] = {0};
    for (int i = 0; i < input_count; ++i) active[i] = 1;
    *output_count = 0;
    for (;;) {
        int chosen_center = -1;
        uint8_t neighborhoods[EP_MAX_N][EP_MAX_N] = {{0}};
        for (int candidate = 0; candidate < input_count; ++candidate) {
            if (!active[candidate]) continue;
            int count = 0;
            for (int other = 0; other < input_count; ++other) {
                if (active[other] && ep_set_distance(n, input[candidate].members,
                        input[other].members, distances) <= delta) {
                    neighborhoods[candidate][other] = 1;
                    ++count;
                }
            }
            if (count >= sigma && (chosen_center < 0 ||
                    ep_cluster_before(&input[candidate], &input[chosen_center], n)))
                chosen_center = candidate;
        }
        if (chosen_center < 0) break;
        EpCluster merged = {0};
        merged.center = input[chosen_center].center;
        for (int other = 0; other < input_count; ++other) {
            if (!neighborhoods[chosen_center][other]) continue;
            active[other] = 0;
            for (int v = 0; v < n; ++v) merged.members[v] |= input[other].members[v];
            for (int e = 0; e < m; ++e) merged.tree[e] |= input[other].tree[e];
            if (other != chosen_center) {
                uint8_t connector[EP_MAX_M] = {0};
                ep_connector(n, adjacent, edge_index, input[chosen_center].members,
                             input[other].members, connector);
                for (int e = 0; e < m; ++e) merged.tree[e] |= connector[e];
            }
        }
        for (int e = 0; e < m; ++e) chosen[e] |= merged.tree[e];
        output[(*output_count)++] = merged;
    }

    int remaining[EP_MAX_N], remaining_count = 0;
    for (int i = 0; i < input_count; ++i) if (active[i]) remaining[remaining_count++] = i;
    for (int i = 1; i < remaining_count; ++i) {
        const int key = remaining[i];
        int position = i;
        while (position > 0 && ep_cluster_before(&input[key], &input[remaining[position - 1]], n)) {
            remaining[position] = remaining[position - 1];
            --position;
        }
        remaining[position] = key;
    }
    for (int i = 0; i < remaining_count; ++i) {
        for (int j = i + 1; j < remaining_count; ++j) {
            const EpCluster *left = &input[remaining[i]], *right = &input[remaining[j]];
            if (ep_set_distance(n, left->members, right->members, distances) <= delta)
                ep_connector(n, adjacent, edge_index, left->members, right->members, chosen);
        }
    }
}

int64_t elkin_peleg_sparse_spanner(const int64_t *input, size_t length,
                                   uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > EP_MAX_INPUT) return -1;
    const int64_t n64 = input[0], m64 = input[1];
    if (n64 < 1 || n64 > EP_MAX_N || m64 < 0 || m64 > EP_MAX_M ||
        length != 2 + 2 * (size_t)m64) return -1;
    const int n = (int)n64, m = (int)m64;
    int edge_index[EP_MAX_N][EP_MAX_N];
    uint8_t adjacent[EP_MAX_N][EP_MAX_N] = {{0}}, chosen[EP_MAX_M] = {0};
    for (int u = 0; u < EP_MAX_N; ++u)
        for (int v = 0; v < EP_MAX_N; ++v) edge_index[u][v] = -1;
    for (int e = 0; e < m; ++e) {
        const int64_t u64 = input[2 + 2 * (size_t)e], v64 = input[3 + 2 * (size_t)e];
        if (u64 < 0 || v64 <= u64 || v64 >= n64) return -1;
        const int u = (int)u64, v = (int)v64;
        if (edge_index[u][v] >= 0) return -1;
        edge_index[u][v] = edge_index[v][u] = e;
        adjacent[u][v] = adjacent[v][u] = 1;
    }
    if (output == NULL || capacity < (size_t)m) return -2;

    int distances[EP_MAX_N][EP_MAX_N];
    for (int source = 0; source < n; ++source)
        ep_bfs_distances(n, adjacent, source, distances[source]);
    EpCluster ground[EP_MAX_N] = {{0}};
    int ground_count = 0;
    uint8_t uncovered[EP_MAX_N] = {0};
    for (int v = 0; v < n; ++v) uncovered[v] = 1;
    while (1) {
        int root = -1;
        for (int v = 0; v < n; ++v) if (uncovered[v]) { root = v; break; }
        if (root < 0) break;
        uint8_t members[EP_MAX_N] = {0};
        int size = 1;
        members[root] = 1;
        for (;;) {
            uint8_t shell[EP_MAX_N] = {0};
            int shell_size = 0;
            for (int v = 0; v < n; ++v) {
                if (members[v]) shell[v] = 1;
                else if (uncovered[v])
                    for (int u = 0; u < n; ++u)
                        if (members[u] && adjacent[u][v]) { shell[v] = 1; break; }
                if (shell[v]) ++shell_size;
            }
            const int size4 = size * size * size * size;
            const int shell4 = shell_size * shell_size * shell_size * shell_size;
            if (shell_size == size || shell4 < n * size4) break;
            for (int v = 0; v < n; ++v) if (shell[v] && !members[v]) { members[v] = 1; ++size; }
        }
        uint8_t shell[EP_MAX_N] = {0};
        for (int v = 0; v < n; ++v) {
            if (members[v]) shell[v] = 1;
            else if (uncovered[v])
                for (int u = 0; u < n; ++u)
                    if (members[u] && adjacent[u][v]) { shell[v] = 1; break; }
        }
        EpCluster cluster = {0};
        cluster.center = root;
        for (int v = 0; v < n; ++v) cluster.members[v] = members[v];
        int cluster_distances[EP_MAX_N];
        cluster.radius = ep_bfs_tree(n, adjacent, edge_index, members, root,
                                     cluster.tree, cluster_distances);
        uint8_t shell_tree[EP_MAX_M] = {0};
        int shell_distances[EP_MAX_N];
        (void)ep_bfs_tree(n, adjacent, edge_index, shell, root, shell_tree, shell_distances);
        for (int e = 0; e < m; ++e) chosen[e] |= shell_tree[e];
        ground[ground_count++] = cluster;
        for (int v = 0; v < n; ++v) if (members[v]) uncovered[v] = 0;
    }

    EpCluster level[EP_MAX_N], superclusters[EP_MAX_N];
    int level_count = 0, supercluster_count = 0;
    for (int i = 0; i < ground_count; ++i)
        if (ground[i].radius == 1) level[level_count++] = ground[i];
    ep_supercluster(n, m, adjacent, edge_index, distances, level, level_count,
                    ep_sigma(n), 16, superclusters, &supercluster_count, chosen);
    EpCluster final_clusters[EP_MAX_N];
    int final_count = 0;
    for (int i = 0; i < supercluster_count; ++i) final_clusters[final_count++] = superclusters[i];
    for (int i = 0; i < ground_count; ++i)
        if (ground[i].radius == 2 || ground[i].radius == 3) final_clusters[final_count++] = ground[i];
    for (int i = 1; i < final_count; ++i) {
        const EpCluster key = final_clusters[i];
        int position = i;
        while (position > 0 && ep_cluster_before(&key, &final_clusters[position - 1], n)) {
            final_clusters[position] = final_clusters[position - 1];
            --position;
        }
        final_clusters[position] = key;
    }
    for (int i = 0; i < final_count; ++i)
        for (int j = i + 1; j < final_count; ++j)
            if (ep_set_distance(n, final_clusters[i].members,
                    final_clusters[j].members, distances) <= 128)
                ep_connector(n, adjacent, edge_index, final_clusters[i].members,
                             final_clusters[j].members, chosen);
    for (int e = 0; e < m; ++e) output[e] = chosen[e];
    return m;
}
