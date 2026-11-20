#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 8, MAX_M = 28, MAX_INPUT = 67, MAX_PIECES = 56, MAX_SPLITS = 28 };
enum { KIND_S = 1, KIND_P = 2, KIND_R = 3 };

typedef struct { int u, v, pair_id; bool real; } EdgeRef;
typedef struct { int edge_count; EdgeRef edges[MAX_M]; } Piece;

static bool connected_without(const bool adjacency[MAX_N][MAX_N], int n, int removed) {
    int start = 0;
    while (start == removed) ++start;
    bool seen[MAX_N] = {false};
    int queue[MAX_N], head = 0, tail = 0;
    seen[start] = true; queue[tail++] = start;
    while (head < tail) {
        int u = queue[head++];
        for (int v = 0; v < n; ++v) {
            if (v != removed && adjacency[u][v] && !seen[v]) {
                seen[v] = true; queue[tail++] = v;
            }
        }
    }
    int reached = 0;
    for (int v = 0; v < n; ++v) if (v != removed && seen[v]) ++reached;
    return reached == n - (removed >= 0 ? 1 : 0);
}

static void components_after_pair(const Piece *piece, int n, int pole_u, int pole_v,
                                  int component[MAX_N], int *component_count) {
    for (int v = 0; v < n; ++v) component[v] = -1;
    *component_count = 0;
    int queue[MAX_N];
    for (int start = 0; start < n; ++start) {
        if (start == pole_u || start == pole_v || component[start] >= 0) continue;
        int head = 0, tail = 0;
        component[start] = *component_count; queue[tail++] = start;
        while (head < tail) {
            int u = queue[head++];
            for (int e = 0; e < piece->edge_count; ++e) {
                int a = piece->edges[e].u, b = piece->edges[e].v;
                if (a == pole_u || a == pole_v || b == pole_u || b == pole_v) continue;
                int other = a == u ? b : b == u ? a : -1;
                if (other >= 0 && component[other] < 0) {
                    component[other] = *component_count; queue[tail++] = other;
                }
            }
        }
        ++*component_count;
    }
}

static bool find_split(const Piece *piece, int n, int *chosen_u, int *chosen_v,
                       bool left_edge[MAX_M]) {
    const int edge_count = piece->edge_count;
    for (int u = 0; u < n; ++u) for (int v = u + 1; v < n; ++v) {
        int component[MAX_N], component_count;
        components_after_pair(piece, n, u, v, component, &component_count);
        int edge_class[MAX_M], sizes[MAX_M] = {0}, direct_count = 0;
        for (int e = 0; e < edge_count; ++e) {
            const EdgeRef edge = piece->edges[e];
            if ((edge.u == u && edge.v == v) || (edge.u == v && edge.v == u)) {
                edge_class[e] = component_count + direct_count++;
            } else {
                int endpoint = edge.u != u && edge.u != v ? edge.u : edge.v;
                edge_class[e] = component[endpoint];
            }
            if (edge_class[e] < 0 || edge_class[e] >= MAX_M) return false;
            ++sizes[edge_class[e]];
        }
        const int class_count = component_count + direct_count;
        int selected = -1;
        for (int c = 0; c < class_count; ++c)
            if (sizes[c] >= 2 && sizes[c] <= edge_count - 2) { selected = c; break; }
        bool use_first_two = false;
        if (selected < 0 && class_count >= 4 && class_count == edge_count) {
            use_first_two = true;
            for (int c = 0; c < class_count; ++c) if (sizes[c] != 1) use_first_two = false;
        }
        if (selected < 0 && !use_first_two) continue;
        for (int e = 0; e < edge_count; ++e)
            left_edge[e] = selected >= 0 ? edge_class[e] == selected : edge_class[e] < 2;
        *chosen_u = u; *chosen_v = v;
        return true;
    }
    return false;
}

static int piece_kind(const Piece *piece) {
    bool present[MAX_N] = {false};
    int vertex_count = 0;
    for (int e = 0; e < piece->edge_count; ++e) {
        int endpoints[2] = {piece->edges[e].u, piece->edges[e].v};
        for (int k = 0; k < 2; ++k) if (!present[endpoints[k]]) {
            present[endpoints[k]] = true; ++vertex_count;
        }
    }
    if (vertex_count == 2 && piece->edge_count >= 3) return KIND_P;
    if (vertex_count == 3 && piece->edge_count == 3) {
        bool pair[MAX_N][MAX_N] = {{false}};
        for (int e = 0; e < 3; ++e) {
            int u = piece->edges[e].u, v = piece->edges[e].v;
            pair[u][v] = pair[v][u] = true;
        }
        int count = 0;
        for (int u = 0; u < MAX_N; ++u) for (int v = u + 1; v < MAX_N; ++v)
            if (pair[u][v]) ++count;
        if (count == 3) return KIND_S;
    }
    return KIND_R;
}

static int find_root(int parent[MAX_PIECES], int item) {
    while (parent[item] != item) {
        parent[item] = parent[parent[item]];
        item = parent[item];
    }
    return item;
}

static void unite(int parent[MAX_PIECES], int left, int right) {
    int a = find_root(parent, left), b = find_root(parent, right);
    if (a != b) parent[b] = a;
}

static int component_count_without_pair(const bool adjacency[MAX_N][MAX_N], int n, int a, int b) {
    bool seen[MAX_N] = {false};
    int count = 0, queue[MAX_N];
    for (int start = 0; start < n; ++start) {
        if (start == a || start == b || seen[start]) continue;
        ++count; int head = 0, tail = 0;
        seen[start] = true; queue[tail++] = start;
        while (head < tail) {
            int u = queue[head++];
            for (int v = 0; v < n; ++v) {
                if (v != a && v != b && adjacency[u][v] && !seen[v]) {
                    seen[v] = true; queue[tail++] = v;
                }
            }
        }
    }
    return count;
}

int64_t two_vertex_cuts_spqr(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > MAX_INPUT) return -1;
    if (input[0] < 3 || input[0] > MAX_N || input[1] < 3 || input[1] > MAX_M) return -1;
    const int n = (int)input[0], m = (int)input[1];
    if (length != (size_t)(2 + n + 2 * m)) return -1;
    int64_t weights[MAX_N];
    for (int v = 0; v < n; ++v) {
        weights[v] = input[2 + v];
        if (weights[v] < 0 || weights[v] > 1000000) return -1;
    }
    bool adjacency[MAX_N][MAX_N] = {{false}};
    int offset = 2 + n;
    Piece pieces[MAX_PIECES] = {0};
    pieces[0].edge_count = m;
    for (int e = 0; e < m; ++e) {
        int64_t left = input[offset + 2 * e], right = input[offset + 2 * e + 1];
        if (left < 0 || left >= n || right < 0 || right >= n || left == right) return -1;
        int u = (int)left, v = (int)right;
        if (adjacency[u][v]) return -1;
        adjacency[u][v] = adjacency[v][u] = true;
        pieces[0].edges[e] = (EdgeRef){u, v, -1, true};
    }
    for (int removed = -1; removed < n; ++removed)
        if (!connected_without(adjacency, n, removed)) return -1;

    int piece_count = 1, split_count = 0;
    int pair_u[MAX_SPLITS], pair_v[MAX_SPLITS];
    bool is_leaf[MAX_PIECES] = {false};
    for (int index = 0; index < piece_count; ++index) {
        bool left_edge[MAX_M] = {false};
        int u = 0, v = 0;
        if (!find_split(&pieces[index], n, &u, &v, left_edge)) {
            is_leaf[index] = true;
            continue;
        }
        if (split_count >= MAX_SPLITS || piece_count + 2 > MAX_PIECES) return -1;
        int left_index = piece_count++, right_index = piece_count++;
        Piece *left = &pieces[left_index], *right = &pieces[right_index];
        left->edge_count = right->edge_count = 0;
        for (int e = 0; e < pieces[index].edge_count; ++e) {
            Piece *target = left_edge[e] ? left : right;
            target->edges[target->edge_count++] = pieces[index].edges[e];
        }
        const int pair_id = split_count++;
        pair_u[pair_id] = u; pair_v[pair_id] = v;
        left->edges[left->edge_count++] = (EdgeRef){u, v, pair_id, false};
        right->edges[right->edge_count++] = (EdgeRef){u, v, pair_id, false};
        if (left->edge_count < 3 || right->edge_count < 3) return -1;
    }

    int kind[MAX_PIECES] = {0};
    int first_leaf[MAX_SPLITS], second_leaf[MAX_SPLITS], occurrences[MAX_SPLITS] = {0};
    for (int p = 0; p < MAX_SPLITS; ++p) first_leaf[p] = second_leaf[p] = -1;
    int parent[MAX_PIECES];
    for (int p = 0; p < piece_count; ++p) {
        parent[p] = p;
        if (is_leaf[p]) kind[p] = piece_kind(&pieces[p]);
    }
    for (int p = 0; p < piece_count; ++p) if (is_leaf[p]) {
        for (int e = 0; e < pieces[p].edge_count; ++e) {
            EdgeRef edge = pieces[p].edges[e];
            if (edge.real) continue;
            if (edge.pair_id < 0 || edge.pair_id >= split_count) return -1;
            int id = edge.pair_id;
            if (++occurrences[id] == 1) first_leaf[id] = p;
            else if (occurrences[id] == 2) second_leaf[id] = p;
            else return -1;
        }
    }
    for (int id = 0; id < split_count; ++id) {
        if (occurrences[id] != 2 || first_leaf[id] == second_leaf[id]) return -1;
        int a = first_leaf[id], b = second_leaf[id];
        if (kind[a] == kind[b] && (kind[a] == KIND_S || kind[a] == KIND_P)) unite(parent, a, b);
    }

    bool candidate[MAX_N][MAX_N] = {{false}};
    for (int id = 0; id < split_count; ++id) candidate[pair_u[id]][pair_v[id]] = true;
    for (int leaf = 0; leaf < piece_count; ++leaf) if (is_leaf[leaf] && find_root(parent, leaf) == leaf) {
        if (kind[leaf] == KIND_S) {
            bool in_group[MAX_N] = {false}, skeleton[MAX_N][MAX_N] = {{false}};
            for (int member = 0; member < piece_count; ++member) {
                if (!is_leaf[member] || find_root(parent, member) != leaf) continue;
                for (int e = 0; e < pieces[member].edge_count; ++e) {
                    EdgeRef edge = pieces[member].edges[e];
                    if (!edge.real) {
                        int id = edge.pair_id;
                        if (find_root(parent, first_leaf[id]) == leaf && find_root(parent, second_leaf[id]) == leaf)
                            continue;
                    }
                    in_group[edge.u] = in_group[edge.v] = true;
                    skeleton[edge.u][edge.v] = skeleton[edge.v][edge.u] = true;
                }
            }
            for (int u = 0; u < n; ++u) for (int v = u + 1; v < n; ++v)
                if (in_group[u] && in_group[v] && !skeleton[u][v]) candidate[u][v] = true;
        } else if (kind[leaf] == KIND_P) {
            int first = -1, second = -1;
            for (int member = 0; member < piece_count; ++member) {
                if (!is_leaf[member] || find_root(parent, member) != leaf) continue;
                for (int e = 0; e < pieces[member].edge_count; ++e) {
                    int endpoints[2] = {pieces[member].edges[e].u, pieces[member].edges[e].v};
                    for (int k = 0; k < 2; ++k) {
                        if (first < 0) first = endpoints[k];
                        else if (endpoints[k] != first && second < 0) second = endpoints[k];
                        else if (endpoints[k] != first && endpoints[k] != second) return -1;
                    }
                }
            }
            if (first < 0 || second < 0) return -1;
            if (first < second) candidate[first][second] = true;
            else candidate[second][first] = true;
        }
    }

    int64_t total = 0;
    for (int u = 0; u < n; ++u) for (int v = u + 1; v < n; ++v) if (candidate[u][v]) {
        int components = component_count_without_pair(adjacency, n, u, v);
        if (components > 1) {
            int64_t term = (weights[u] % 998244353) * (weights[v] % 998244353) % 998244353;
            total = (total + term * (components - 1)) % 998244353;
        }
    }
    return total;
}
