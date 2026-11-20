module elkin_peleg_sparse_spanner;

const usz MAX_N = 20;
const usz MAX_M = 190;
const usz MAX_INPUT = 383;
const int INF = 1000;

struct EpCluster { int center; int radius; bool[20] members; bool[190] tree; }
struct EpContext {
    int n; int m;
    bool[20][20] adjacent;
    int[20][20] edge_index;
    int[20][20] distance;
}

fn void ep_bfs(EpContext* c, int source, int* distance) {
    int[20] queue = zeroed;
    int head = 0, tail = 0;
    for (int v = 0; v < c.n; ++v) distance[v] = INF;
    distance[source] = 0;
    queue[tail++] = source;
    while (head < tail) {
        int vertex = queue[head++];
        for (int neighbor = 0; neighbor < c.n; ++neighbor) {
            if (c.adjacent[vertex][neighbor] && distance[neighbor] == INF) {
                distance[neighbor] = distance[vertex] + 1;
                queue[tail++] = neighbor;
            }
        }
    }
}

fn int ep_edge_id(EpContext* c, int a, int b) {
    return a < b ? c.edge_index[a][b] : c.edge_index[b][a];
}

fn int ep_tree(EpContext* c, bool* allowed, int root, bool* tree, int* distance) {
    int[20] parent = zeroed, queue = zeroed;
    int head = 0, tail = 0, radius = 0;
    for (int v = 0; v < c.n; ++v) { distance[v] = INF; parent[v] = -1; }
    distance[root] = 0; queue[tail++] = root;
    while (head < tail) {
        int vertex = queue[head++];
        for (int neighbor = 0; neighbor < c.n; ++neighbor) {
            if (allowed[neighbor] && c.adjacent[vertex][neighbor] && distance[neighbor] == INF) {
                distance[neighbor] = distance[vertex] + 1;
                parent[neighbor] = vertex;
                queue[tail++] = neighbor;
            }
        }
    }
    for (int vertex = 0; vertex < c.n; ++vertex) {
        if (!allowed[vertex]) continue;
        if (distance[vertex] > radius) radius = distance[vertex];
        if (vertex != root) tree[ep_edge_id(c, vertex, parent[vertex])] = true;
    }
    return radius;
}

fn int ep_set_distance(EpContext* c, bool* left, bool* right) {
    int best = INF;
    for (int u = 0; u < c.n; ++u) if (left[u])
        for (int v = 0; v < c.n; ++v) if (right[v] && c.distance[u][v] < best)
            best = c.distance[u][v];
    return best;
}

fn bool ep_cluster_before(EpCluster* left, EpCluster* right, int n) {
    if (left.center != right.center) return left.center < right.center;
    int li = 0, ri = 0;
    while (li < n && ri < n) {
        while (li < n && !left.members[li]) ++li;
        while (ri < n && !right.members[ri]) ++ri;
        if (li == n || ri == n) break;
        if (li != ri) return li < ri;
        ++li; ++ri;
    }
    while (li < n && !left.members[li]) ++li;
    while (ri < n && !right.members[ri]) ++ri;
    return li == n && ri != n;
}

fn void ep_connector(EpContext* c, bool* left, bool* right, bool* result) {
    int best_distance = INF, best_length = 0;
    bool have_best = false;
    int[20] best_path = zeroed;
    for (int source = 0; source < c.n; ++source) {
        if (!left[source]) continue;
        int[20] distance = zeroed, parent = zeroed, queue = zeroed;
        for (int v = 0; v < c.n; ++v) { distance[v] = INF; parent[v] = -1; }
        int head = 0, tail = 0;
        distance[source] = 0; queue[tail++] = source;
        while (head < tail) {
            int vertex = queue[head++];
            for (int neighbor = 0; neighbor < c.n; ++neighbor) {
                if (c.adjacent[vertex][neighbor] && distance[neighbor] == INF) {
                    distance[neighbor] = distance[vertex] + 1;
                    parent[neighbor] = vertex;
                    queue[tail++] = neighbor;
                }
            }
        }
        for (int target = 0; target < c.n; ++target) {
            if (!right[target] || distance[target] == INF || distance[target] > best_distance) continue;
            int[20] reverse_path = zeroed, candidate = zeroed;
            int path_length = 0, vertex = target;
            while (vertex >= 0 && path_length < c.n) {
                reverse_path[path_length++] = vertex;
                if (vertex == source) break;
                vertex = parent[vertex];
            }
            if (path_length == 0 || reverse_path[path_length - 1] != source) continue;
            for (int i = 0; i < path_length; ++i) candidate[i] = reverse_path[path_length - 1 - i];
            bool earlier = !have_best || distance[target] < best_distance;
            if (!earlier && distance[target] == best_distance) {
                for (int i = 0; i < path_length; ++i) {
                    if (candidate[i] != best_path[i]) { earlier = candidate[i] < best_path[i]; break; }
                }
            }
            if (earlier) {
                have_best = true; best_distance = distance[target]; best_length = path_length;
                for (int i = 0; i < path_length; ++i) best_path[i] = candidate[i];
            }
        }
    }
    for (int i = 1; i < best_length; ++i) result[ep_edge_id(c, best_path[i - 1], best_path[i])] = true;
}

fn int ep_sigma(int n) {
    int sigma = 1;
    while (sigma * sigma * sigma * sigma < n) ++sigma;
    return sigma;
}

fn void ep_supercluster(EpContext* c, EpCluster* input, int input_count, int sigma, int delta,
                        EpCluster* output, int* output_count, bool* chosen) {
    bool[20] active = zeroed;
    bool[20][20] neighborhoods = zeroed;
    for (int i = 0; i < input_count; ++i) active[i] = true;
    output_count[0] = 0;
    while (true) {
        int center = -1;
        for (int candidate = 0; candidate < input_count; ++candidate) {
            if (!active[candidate]) continue;
            int count = 0;
            for (int other = 0; other < input_count; ++other) {
                if (active[other] && ep_set_distance(c, &input[candidate].members[0], &input[other].members[0]) <= delta) {
                    neighborhoods[candidate][other] = true; ++count;
                }
            }
            if (count >= sigma && (center < 0 || ep_cluster_before(&input[candidate], &input[center], c.n))) center = candidate;
        }
        if (center < 0) break;
        EpCluster merged = zeroed;
        merged.center = input[center].center;
        for (int other = 0; other < input_count; ++other) {
            if (!neighborhoods[center][other]) continue;
            active[other] = false;
            for (int v = 0; v < c.n; ++v) merged.members[v] = merged.members[v] || input[other].members[v];
            for (int e = 0; e < c.m; ++e) merged.tree[e] = merged.tree[e] || input[other].tree[e];
            if (other != center) {
                bool[MAX_M] connector = zeroed;
                ep_connector(c, &input[center].members[0], &input[other].members[0], &connector[0]);
                for (int e = 0; e < c.m; ++e) merged.tree[e] = merged.tree[e] || connector[e];
            }
        }
        for (int e = 0; e < c.m; ++e) chosen[e] = chosen[e] || merged.tree[e];
        output[output_count[0]++] = merged;
        for (int i = 0; i < input_count; ++i) for (int j = 0; j < input_count; ++j) neighborhoods[i][j] = false;
    }
    int[20] remaining = zeroed;
    int remaining_count = 0;
    for (int i = 0; i < input_count; ++i) if (active[i]) remaining[remaining_count++] = i;
    for (int i = 1; i < remaining_count; ++i) {
        int key = remaining[i], position = i;
        while (position > 0 && ep_cluster_before(&input[key], &input[remaining[position - 1]], c.n)) {
            remaining[position] = remaining[position - 1]; --position;
        }
        remaining[position] = key;
    }
    for (int i = 0; i < remaining_count; ++i) for (int j = i + 1; j < remaining_count; ++j) {
        EpCluster* left = &input[remaining[i]]; EpCluster* right = &input[remaining[j]];
        if (ep_set_distance(c, &left.members[0], &right.members[0]) <= delta)
            ep_connector(c, &left.members[0], &right.members[0], chosen);
    }
}

fn long elkin_peleg_sparse_spanner(long* input, usz length, char* output, usz capacity)
        @export("elkin_peleg_sparse_spanner") {
    if (input == null || length < 2 || length > MAX_INPUT) return -1;
    long n64 = input[0], m64 = input[1];
    if (n64 < 1 || n64 > 20 || m64 < 0 || m64 > 190 || length != 2 + 2 * (usz)m64) return -1;
    int n = (int)n64, m = (int)m64;
    EpContext c = zeroed; c.n = n; c.m = m;
    for (int a = 0; a < 20; ++a) for (int b = 0; b < 20; ++b) c.edge_index[a][b] = -1;
    for (int e = 0; e < m; ++e) {
        long u64 = input[2 + 2 * (usz)e], v64 = input[3 + 2 * (usz)e];
        if (u64 < 0 || v64 <= u64 || v64 >= n64) return -1;
        int u = (int)u64, v = (int)v64;
        if (c.edge_index[u][v] >= 0) return -1;
        c.edge_index[u][v] = e; c.edge_index[v][u] = e;
        c.adjacent[u][v] = true; c.adjacent[v][u] = true;
    }
    if (output == null || capacity < (usz)m) return -2;
    for (int source = 0; source < n; ++source) ep_bfs(&c, source, &c.distance[source][0]);

    EpCluster[20] ground = zeroed;
    int ground_count = 0;
    bool[20] uncovered = zeroed;
    for (int v = 0; v < n; ++v) uncovered[v] = true;
    bool[MAX_M] chosen = zeroed;
    while (true) {
        int root = -1;
        for (int v = 0; v < n; ++v) if (uncovered[v]) { root = v; break; }
        if (root < 0) break;
        bool[20] members = zeroed; members[root] = true;
        int size = 1;
        while (true) {
            bool[20] shell = zeroed; int shell_size = 0;
            for (int v = 0; v < n; ++v) {
                if (members[v]) shell[v] = true;
                else if (uncovered[v]) for (int u = 0; u < n; ++u)
                    if (members[u] && c.adjacent[u][v]) { shell[v] = true; break; }
                if (shell[v]) ++shell_size;
            }
            if (shell_size == size || shell_size * shell_size * shell_size * shell_size < n * size * size * size * size) break;
            for (int v = 0; v < n; ++v) if (shell[v] && !members[v]) { members[v] = true; ++size; }
        }
        bool[20] shell = zeroed;
        for (int v = 0; v < n; ++v) {
            if (members[v]) shell[v] = true;
            else if (uncovered[v]) for (int u = 0; u < n; ++u)
                if (members[u] && c.adjacent[u][v]) { shell[v] = true; break; }
        }
        EpCluster cluster = zeroed; cluster.center = root;
        for (int v = 0; v < n; ++v) cluster.members[v] = members[v];
        int[20] tree_distance = zeroed;
        cluster.radius = ep_tree(&c, &members[0], root, &cluster.tree[0], &tree_distance[0]);
        bool[MAX_M] shell_tree = zeroed;
        ep_tree(&c, &shell[0], root, &shell_tree[0], &tree_distance[0]);
        for (int e = 0; e < m; ++e) chosen[e] = chosen[e] || shell_tree[e];
        ground[ground_count++] = cluster;
        for (int v = 0; v < n; ++v) if (members[v]) uncovered[v] = false;
    }
    EpCluster[20] level = zeroed, superclusters = zeroed;
    int level_count = 0, supercluster_count = 0;
    for (int i = 0; i < ground_count; ++i) if (ground[i].radius == 1) level[level_count++] = ground[i];
    ep_supercluster(&c, &level[0], level_count, ep_sigma(n), 16,
                    &superclusters[0], &supercluster_count, &chosen[0]);
    EpCluster[20] final_clusters = zeroed; int final_count = 0;
    for (int i = 0; i < supercluster_count; ++i) final_clusters[final_count++] = superclusters[i];
    for (int i = 0; i < ground_count; ++i)
        if (ground[i].radius == 2 || ground[i].radius == 3) final_clusters[final_count++] = ground[i];
    for (int i = 1; i < final_count; ++i) {
        EpCluster key = final_clusters[i]; int pos = i;
        while (pos > 0 && ep_cluster_before(&key, &final_clusters[pos - 1], n)) {
            final_clusters[pos] = final_clusters[pos - 1]; --pos;
        }
        final_clusters[pos] = key;
    }
    for (int i = 0; i < final_count; ++i) for (int j = i + 1; j < final_count; ++j)
        if (ep_set_distance(&c, &final_clusters[i].members[0], &final_clusters[j].members[0]) <= 128)
            ep_connector(&c, &final_clusters[i].members[0], &final_clusters[j].members[0], &chosen[0]);
    for (int e = 0; e < m; ++e) output[e] = chosen[e] ? 1 : 0;
    return (long)m;
}
