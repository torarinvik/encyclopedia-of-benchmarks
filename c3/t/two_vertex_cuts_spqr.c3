module two_vertex_cuts_spqr;

const int MAX_N = 8;
const int MAX_M = 28;
const int MAX_INPUT = 67;
const int MAX_PIECES = 56;
const int MAX_SPLITS = 28;
const long MODULUS = 998244353;
const int KIND_S = 1;
const int KIND_P = 2;

struct EdgeRef { int u; int v; int pair_id; bool real; }
struct Piece { int edge_count; EdgeRef[MAX_M] edges; }

fn bool connected_without(bool* adjacency, int n, int removed) {
    int start = 0;
    while (start == removed) start++;
    bool[MAX_N] seen = {};
    int[MAX_N] queue = {};
    int head = 0, tail = 1;
    seen[start] = true; queue[0] = start;
    while (head < tail) {
        int u = queue[head++];
        for (int v = 0; v < n; v++) {
            if (v != removed && adjacency[u * MAX_N + v] && !seen[v]) {
                seen[v] = true; queue[tail++] = v;
            }
        }
    }
    int reached = 0;
    for (int v = 0; v < n; v++) if (v != removed && seen[v]) reached++;
    return reached == n - (removed >= 0 ? 1 : 0);
}

fn void components_after_pair(Piece* piece, int n, int a, int b, int* component, int* count) {
    for (int v = 0; v < n; v++) component[v] = -1;
    *count = 0;
    int[MAX_N] queue = {};
    for (int start = 0; start < n; start++) {
        if (start == a || start == b || component[start] >= 0) continue;
        int head = 0, tail = 1;
        component[start] = *count; queue[0] = start;
        while (head < tail) {
            int u = queue[head++];
            for (int e = 0; e < piece->edge_count; e++) {
                EdgeRef edge = piece->edges[e];
                if (edge.u == a || edge.u == b || edge.v == a || edge.v == b) continue;
                int other = edge.u == u ? edge.v : edge.v == u ? edge.u : -1;
                if (other >= 0 && component[other] < 0) { component[other] = *count; queue[tail++] = other; }
            }
        }
        *count = *count + 1;
    }
}

fn bool find_split(Piece* piece, int n, int* chosen_u, int* chosen_v, bool* left_edge) {
    int edge_count = piece->edge_count;
    for (int u = 0; u < n; u++) for (int v = u + 1; v < n; v++) {
        int[MAX_N] component = {}; int component_count = 0;
        components_after_pair(piece, n, u, v, &component[0], &component_count);
        int[MAX_M] edge_class = {}, sizes = {};
        int direct_count = 0;
        for (int e = 0; e < edge_count; e++) {
            EdgeRef edge = piece->edges[e];
            if ((edge.u == u && edge.v == v) || (edge.u == v && edge.v == u))
                edge_class[e] = component_count + direct_count++;
            else {
                int endpoint = edge.u != u && edge.u != v ? edge.u : edge.v;
                if (component[endpoint] < 0) return false;
                edge_class[e] = component[endpoint];
            }
            if (edge_class[e] < 0 || edge_class[e] >= MAX_M) return false;
            sizes[edge_class[e]]++;
        }
        int class_count = component_count + direct_count;
        int selected = -1;
        for (int c = 0; c < class_count; c++)
            if (sizes[c] >= 2 && sizes[c] <= edge_count - 2) { selected = c; break; }
        bool use_first_two = selected < 0 && class_count >= 4 && class_count == edge_count;
        if (use_first_two) for (int c = 0; c < class_count; c++) if (sizes[c] != 1) use_first_two = false;
        if (selected < 0 && !use_first_two) continue;
        for (int e = 0; e < edge_count; e++) left_edge[e] = selected >= 0 ? edge_class[e] == selected : edge_class[e] < 2;
        *chosen_u = u; *chosen_v = v;
        return true;
    }
    return false;
}

fn int piece_kind(Piece* piece) {
    bool[MAX_N] present = {};
    int vertex_count = 0;
    for (int e = 0; e < piece->edge_count; e++) {
        int[2] ends = {piece->edges[e].u, piece->edges[e].v};
        for (int k = 0; k < 2; k++) if (!present[ends[k]]) { present[ends[k]] = true; vertex_count++; }
    }
    if (vertex_count == 2 && piece->edge_count >= 3) return KIND_P;
    if (vertex_count == 3 && piece->edge_count == 3) {
        bool[MAX_N][MAX_N] pair = {};
        for (int e = 0; e < 3; e++) { int u = piece->edges[e].u, v = piece->edges[e].v; pair[u][v] = pair[v][u] = true; }
        int count = 0;
        for (int u = 0; u < MAX_N; u++) for (int v = u + 1; v < MAX_N; v++) if (pair[u][v]) count++;
        if (count == 3) return KIND_S;
    }
    return 3;
}

fn int find_root(int* parent, int item) {
    int current = item;
    while (parent[current] != current) { parent[current] = parent[parent[current]]; current = parent[current]; }
    return current;
}
fn void unite(int* parent, int a, int b) {
    int left = find_root(parent, a), right = find_root(parent, b);
    if (left != right) parent[right] = left;
}

fn int pair_components(bool* adjacency, int n, int a, int b) {
    bool[MAX_N] seen = {};
    int[MAX_N] queue = {};
    int count = 0;
    for (int start = 0; start < n; start++) {
        if (start == a || start == b || seen[start]) continue;
        count++; int head = 0, tail = 1; seen[start] = true; queue[0] = start;
        while (head < tail) {
            int u = queue[head++];
            for (int v = 0; v < n; v++)
                if (v != a && v != b && adjacency[u * MAX_N + v] && !seen[v]) { seen[v] = true; queue[tail++] = v; }
        }
    }
    return count;
}

fn long two_vertex_cuts_spqr(long* input, usz length) @export("two_vertex_cuts_spqr") {
    if (input == null || length < 2 || length > MAX_INPUT) return -1;
    if (input[0] < 3 || input[0] > MAX_N || input[1] < 3 || input[1] > MAX_M) return -1;
    int n = (int)input[0], m = (int)input[1];
    if (length != (usz)(2 + n + 2 * m)) return -1;
    long[MAX_N] weights = {};
    for (int v = 0; v < n; v++) { weights[v] = input[2 + v]; if (weights[v] < 0 || weights[v] > 1000000) return -1; }
    bool[MAX_N * MAX_N] adjacency = {};
    Piece[MAX_PIECES] pieces = {};
    pieces[0].edge_count = m;
    int offset = 2 + n;
    for (int e = 0; e < m; e++) {
        long left = input[offset + 2 * e], right = input[offset + 2 * e + 1];
        if (left < 0 || left >= n || right < 0 || right >= n || left == right) return -1;
        int u = (int)left, v = (int)right;
        if (adjacency[u * MAX_N + v]) return -1;
        adjacency[u * MAX_N + v] = adjacency[v * MAX_N + u] = true;
        pieces[0].edges[e] = {u, v, -1, true};
    }
    for (int removed = -1; removed < n; removed++) if (!connected_without(&adjacency[0], n, removed)) return -1;

    int piece_count = 1, split_count = 0;
    int[MAX_SPLITS] pair_u = {}, pair_v = {};
    bool[MAX_PIECES] is_leaf = {};
    for (int index = 0; index < piece_count; index++) {
        bool[MAX_M] left_edge = {}; int u = 0, v = 0;
        if (!find_split(&pieces[index], n, &u, &v, &left_edge[0])) { is_leaf[index] = true; continue; }
        if (split_count >= MAX_SPLITS || piece_count + 2 > MAX_PIECES) return -1;
        int left_index = piece_count++, right_index = piece_count++;
        pieces[left_index].edge_count = 0; pieces[right_index].edge_count = 0;
        for (int e = 0; e < pieces[index].edge_count; e++) {
            Piece* target = left_edge[e] ? &pieces[left_index] : &pieces[right_index];
            target->edges[target->edge_count++] = pieces[index].edges[e];
        }
        int pair_id = split_count++; pair_u[pair_id] = u; pair_v[pair_id] = v;
        pieces[left_index].edges[pieces[left_index].edge_count++] = {u, v, pair_id, false};
        pieces[right_index].edges[pieces[right_index].edge_count++] = {u, v, pair_id, false};
        if (pieces[left_index].edge_count < 3 || pieces[right_index].edge_count < 3) return -1;
    }

    int[MAX_PIECES] kind = {}, parent = {};
    int[MAX_SPLITS] first_leaf = {}, second_leaf = {}, occurrences = {};
    for (int id = 0; id < MAX_SPLITS; id++) first_leaf[id] = second_leaf[id] = -1;
    for (int p = 0; p < piece_count; p++) { parent[p] = p; if (is_leaf[p]) kind[p] = piece_kind(&pieces[p]); }
    for (int p = 0; p < piece_count; p++) if (is_leaf[p]) for (int e = 0; e < pieces[p].edge_count; e++) {
        EdgeRef edge = pieces[p].edges[e]; if (edge.real) continue;
        if (edge.pair_id < 0 || edge.pair_id >= split_count) return -1;
        int id = edge.pair_id;
        if (++occurrences[id] == 1) first_leaf[id] = p;
        else if (occurrences[id] == 2) second_leaf[id] = p;
        else return -1;
    }
    for (int id = 0; id < split_count; id++) {
        if (occurrences[id] != 2 || first_leaf[id] == second_leaf[id]) return -1;
        int a = first_leaf[id], b = second_leaf[id];
        if (kind[a] == kind[b] && (kind[a] == KIND_S || kind[a] == KIND_P)) unite(&parent[0], a, b);
    }
    bool[MAX_N][MAX_N] candidate = {};
    for (int id = 0; id < split_count; id++) candidate[pair_u[id]][pair_v[id]] = true;
    for (int leaf = 0; leaf < piece_count; leaf++) if (is_leaf[leaf] && find_root(&parent[0], leaf) == leaf) {
        if (kind[leaf] == KIND_S) {
            bool[MAX_N] in_group = {}; bool[MAX_N][MAX_N] skeleton = {};
            for (int member = 0; member < piece_count; member++) if (is_leaf[member] && find_root(&parent[0], member) == leaf) {
                for (int e = 0; e < pieces[member].edge_count; e++) {
                    EdgeRef edge = pieces[member].edges[e];
                    if (!edge.real && find_root(&parent[0], first_leaf[edge.pair_id]) == leaf && find_root(&parent[0], second_leaf[edge.pair_id]) == leaf) continue;
                    in_group[edge.u] = in_group[edge.v] = true;
                    skeleton[edge.u][edge.v] = skeleton[edge.v][edge.u] = true;
                }
            }
            for (int u = 0; u < n; u++) for (int v = u + 1; v < n; v++) if (in_group[u] && in_group[v] && !skeleton[u][v]) candidate[u][v] = true;
        } else if (kind[leaf] == KIND_P) {
            int first = -1, second = -1;
            for (int member = 0; member < piece_count; member++) if (is_leaf[member] && find_root(&parent[0], member) == leaf)
                for (int e = 0; e < pieces[member].edge_count; e++) for (int k = 0; k < 2; k++) {
                    int endpoint = k == 0 ? pieces[member].edges[e].u : pieces[member].edges[e].v;
                    if (first < 0) first = endpoint;
                    else if (endpoint != first && second < 0) second = endpoint;
                    else if (endpoint != first && endpoint != second) return -1;
                }
            if (first < 0 || second < 0) return -1;
            candidate[first < second ? first : second][first < second ? second : first] = true;
        }
    }
    long total = 0;
    for (int u = 0; u < n; u++) for (int v = u + 1; v < n; v++) if (candidate[u][v]) {
        int components = pair_components(&adjacency[0], n, u, v);
        if (components > 1) total = (total + (weights[u] % MODULUS) * (weights[v] % MODULUS) % MODULUS * (components - 1)) % MODULUS;
    }
    return total;
}
