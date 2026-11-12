#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_N 16
#define MAX_Q 32
#define MAX_TOKENS (MAX_N + 2 * (MAX_N - 1 + MAX_Q))
#define MAX_INPUT (3 * MAX_N + 5 * MAX_Q + 1)
#define MAX_DELTA INT64_C(1000)

typedef struct {
    int left, right, parent;
    uint32_t priority;
    int sequence_size, marker_count;
    bool marker;
    int64_t own_value, sum, lazy_add;
} TourNode;

typedef struct {
    TourNode nodes[MAX_TOKENS];
    int next_node;
    uint32_t random_state;
} EulerTour;

static int seq_size(const EulerTour *tour, int node) {
    return node < 0 ? 0 : tour->nodes[node].sequence_size;
}
static int marker_count(const EulerTour *tour, int node) {
    return node < 0 ? 0 : tour->nodes[node].marker_count;
}
static int64_t tour_sum(const EulerTour *tour, int node) {
    return node < 0 ? 0 : tour->nodes[node].sum;
}
static void pull(EulerTour *tour, int node) {
    TourNode *n = &tour->nodes[node];
    n->sequence_size = 1 + seq_size(tour, n->left) + seq_size(tour, n->right);
    n->marker_count = (n->marker ? 1 : 0) + marker_count(tour, n->left) + marker_count(tour, n->right);
    n->sum = n->own_value + tour_sum(tour, n->left) + tour_sum(tour, n->right);
}
static void apply_add(EulerTour *tour, int node, int64_t delta) {
    if (node < 0 || tour->nodes[node].marker_count == 0) return;
    TourNode *n = &tour->nodes[node];
    n->sum += delta * n->marker_count;
    if (n->marker) n->own_value += delta;
    n->lazy_add += delta;
}
static void push(EulerTour *tour, int node) {
    TourNode *n = &tour->nodes[node];
    if (n->lazy_add == 0) return;
    apply_add(tour, n->left, n->lazy_add);
    apply_add(tour, n->right, n->lazy_add);
    n->lazy_add = 0;
}
static uint32_t next_priority(EulerTour *tour) {
    uint32_t x = tour->random_state;
    x ^= x << 13;
    x ^= x >> 17;
    x ^= x << 5;
    tour->random_state = x;
    return x;
}
static int new_node(EulerTour *tour, bool is_marker, int64_t value) {
    if (tour->next_node >= MAX_TOKENS) return -1;
    int id = tour->next_node++;
    TourNode node = {0};
    node.left = node.right = node.parent = -1;
    node.priority = next_priority(tour);
    node.sequence_size = 1;
    node.marker_count = is_marker ? 1 : 0;
    node.marker = is_marker;
    node.own_value = is_marker ? value : 0;
    node.sum = is_marker ? value : 0;
    tour->nodes[id] = node;
    return id;
}
static void split(EulerTour *tour, int root, int count, int *first, int *second) {
    if (root < 0) { *first = -1; *second = -1; return; }
    push(tour, root);
    tour->nodes[root].parent = -1;
    int left = tour->nodes[root].left;
    if (seq_size(tour, left) >= count) {
        int middle;
        split(tour, left, count, first, &middle);
        tour->nodes[root].left = middle;
        if (middle >= 0) tour->nodes[middle].parent = root;
        pull(tour, root);
        *second = root;
    } else {
        int middle;
        split(tour, tour->nodes[root].right,
              count - seq_size(tour, left) - 1, &middle, second);
        tour->nodes[root].right = middle;
        if (middle >= 0) tour->nodes[middle].parent = root;
        pull(tour, root);
        *first = root;
    }
    if (*first >= 0) tour->nodes[*first].parent = -1;
    if (*second >= 0) tour->nodes[*second].parent = -1;
}
static int merge(EulerTour *tour, int first, int second) {
    if (first < 0) { if (second >= 0) tour->nodes[second].parent = -1; return second; }
    if (second < 0) { tour->nodes[first].parent = -1; return first; }
    tour->nodes[first].parent = -1;
    tour->nodes[second].parent = -1;
    if (tour->nodes[first].priority >= tour->nodes[second].priority) {
        push(tour, first);
        int joined = merge(tour, tour->nodes[first].right, second);
        tour->nodes[first].right = joined;
        if (joined >= 0) tour->nodes[joined].parent = first;
        pull(tour, first);
        tour->nodes[first].parent = -1;
        return first;
    }
    push(tour, second);
    int joined = merge(tour, first, tour->nodes[second].left);
    tour->nodes[second].left = joined;
    if (joined >= 0) tour->nodes[joined].parent = second;
    pull(tour, second);
    tour->nodes[second].parent = -1;
    return second;
}
static int root_of(EulerTour *tour, int node) {
    while (tour->nodes[node].parent >= 0) node = tour->nodes[node].parent;
    return node;
}
static int rank_of(const EulerTour *tour, int node) {
    int result = seq_size(tour, tour->nodes[node].left);
    while (tour->nodes[node].parent >= 0) {
        int parent = tour->nodes[node].parent;
        if (tour->nodes[parent].right == node)
            result += 1 + seq_size(tour, tour->nodes[parent].left);
        node = parent;
    }
    return result;
}
static int rotate_to(EulerTour *tour, int node) {
    int root = root_of(tour, node), first, second;
    split(tour, root, rank_of(tour, node), &first, &second);
    return merge(tour, second, first);
}
static bool link_tours(EulerTour *tour, const int *markers, int u, int v,
                       int *uv_out, int *vu_out) {
    int root_u = root_of(tour, markers[u]);
    int root_v = root_of(tour, markers[v]);
    if (root_u == root_v) return false;
    int index_u = rank_of(tour, markers[u]);
    int index_v = rank_of(tour, markers[v]);
    int a0, a1, b0, b_tail, vm, b1;
    split(tour, root_u, index_u + 1, &a0, &a1);
    split(tour, root_v, index_v, &b0, &b_tail);
    split(tour, b_tail, 1, &vm, &b1);
    int uv = new_node(tour, false, 0), vu = new_node(tour, false, 0);
    if (uv < 0 || vu < 0) return false;
    int root = merge(tour, a0, uv);
    root = merge(tour, root, b1);
    root = merge(tour, root, b0);
    root = merge(tour, root, vm);
    root = merge(tour, root, vu);
    (void)merge(tour, root, a1);
    *uv_out = uv;
    *vu_out = vu;
    return true;
}
static bool cut_tours(EulerTour *tour, int uv, int vu) {
    int root = rotate_to(tour, uv), first, rest, side_v, tail, reverse, side_u;
    int reverse_rank = rank_of(tour, vu);
    if (reverse_rank <= 0) return false;
    split(tour, root, 1, &first, &rest);
    split(tour, rest, reverse_rank - 1, &side_v, &tail);
    split(tour, tail, 1, &reverse, &side_u);
    if (first != uv || reverse != vu) return false;
    tour->nodes[uv].left = tour->nodes[uv].right = tour->nodes[uv].parent = -1;
    tour->nodes[vu].left = tour->nodes[vu].right = tour->nodes[vu].parent = -1;
    (void)side_v;
    (void)side_u;
    return true;
}
static bool side_operation(EulerTour *tour, int uv, int vu, bool update,
                           int64_t delta, int64_t *answer) {
    int root = rotate_to(tour, uv), reverse_rank = rank_of(tour, vu);
    if (reverse_rank <= 0) return false;
    int edge, rest, side, tail;
    split(tour, root, 1, &edge, &rest);
    split(tour, rest, reverse_rank - 1, &side, &tail);
    if (edge != uv || side < 0) return false;
    if (update) apply_add(tour, side, delta);
    else *answer = tour_sum(tour, side);
    int joined = merge(tour, edge, side);
    (void)merge(tour, joined, tail);
    return true;
}
static bool connected(bool adjacency[MAX_N][MAX_N], int n, int start, int goal) {
    bool seen[MAX_N] = {false};
    int queue[MAX_N], head = 0, tail = 0;
    queue[tail++] = start;
    seen[start] = true;
    while (head < tail) {
        int u = queue[head++];
        if (u == goal) return true;
        for (int v = 0; v < n; ++v) {
            if (adjacency[u][v] && !seen[v]) { seen[v] = true; queue[tail++] = v; }
        }
    }
    return false;
}
static bool validate_fields(const int64_t *input, int n, int q, int *queries) {
    for (int i = 0; i < n; ++i)
        if (input[2 + i] < 0 || input[2 + i] > MAX_DELTA) return false;
    int edge_start = 2 + n, operations = edge_start + 2 * (n - 1);
    for (int i = 0; i < n - 1; ++i) {
        int64_t u = input[edge_start + 2 * i], v = input[edge_start + 2 * i + 1];
        if (u < 0 || u >= n || v < 0 || v >= n || u == v) return false;
    }
    *queries = 0;
    for (int i = 0; i < q; ++i) {
        int at = operations + 5 * i;
        int64_t kind = input[at], v = input[at + 1], p = input[at + 2];
        int64_t arg = input[at + 3], reserved = input[at + 4];
        if (kind == 0) {
            if (v < 0 || v >= n || p < 0 || p >= n || arg < 0 || arg >= n ||
                reserved < 0 || reserved >= n || v == p || arg == reserved) return false;
        } else if (kind == 1) {
            if (v < 0 || v >= n || p < 0 || p >= n || v == p ||
                arg < 0 || arg > MAX_DELTA || reserved != 0) return false;
        } else if (kind == 2) {
            if (v < 0 || v >= n || p < 0 || p >= n || v == p || arg != 0 || reserved != 0) return false;
            ++*queries;
        } else return false;
    }
    return true;
}
static bool validate_topology(const int64_t *input, int n, int q) {
    bool adjacency[MAX_N][MAX_N] = {{false}};
    int edge_start = 2 + n, operations = edge_start + 2 * (n - 1);
    for (int i = 0; i < n - 1; ++i) {
        int u = (int)input[edge_start + 2 * i], v = (int)input[edge_start + 2 * i + 1];
        if (adjacency[u][v]) return false;
        adjacency[u][v] = adjacency[v][u] = true;
    }
    for (int v = 0; v < n; ++v) if (!connected(adjacency, n, 0, v)) return false;
    for (int i = 0; i < q; ++i) {
        int at = operations + 5 * i;
        int kind = (int)input[at], v = (int)input[at + 1], p = (int)input[at + 2];
        int a = (int)input[at + 3], b = (int)input[at + 4];
        if (kind == 0) {
            if (!adjacency[v][p]) return false;
            adjacency[v][p] = adjacency[p][v] = false;
            if (connected(adjacency, n, a, b)) return false;
            adjacency[a][b] = adjacency[b][a] = true;
        } else if (!adjacency[v][p]) return false;
    }
    return true;
}
static void put_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (int byte = 0; byte < 8; ++byte) output[offset + (size_t)byte] = (uint8_t)(bits >> (8 * byte));
}

extern "C" int64_t dynamic_tree_subtree_add_subtree_sum(const int64_t *input, size_t length,
                                                         uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT) return -1;
    int64_t n64 = input[0], q64 = input[1];
    if (n64 < 1 || n64 > MAX_N || q64 < 0 || q64 > MAX_Q) return -1;
    int n = (int)n64, q = (int)q64, queries = 0;
    if (length != (size_t)(3 * n + 5 * q) || !validate_fields(input, n, q, &queries) ||
        !validate_topology(input, n, q)) return -1;
    size_t output_bytes = (size_t)queries * 8;
    if (output_bytes && (output == NULL || capacity < output_bytes)) return -2;

    EulerTour tour = {0};
    tour.random_state = UINT32_C(0x9e3779b9);
    int markers[MAX_N], directed[MAX_N][MAX_N];
    for (int u = 0; u < MAX_N; ++u) for (int v = 0; v < MAX_N; ++v) directed[u][v] = -1;
    for (int i = 0; i < n; ++i) markers[i] = new_node(&tour, true, input[2 + i]);
    int edge_start = 2 + n, operations = edge_start + 2 * (n - 1);
    for (int i = 0; i < n - 1; ++i) {
        int u = (int)input[edge_start + 2 * i], v = (int)input[edge_start + 2 * i + 1];
        int uv, vu;
        if (!link_tours(&tour, markers, u, v, &uv, &vu)) return -1;
        directed[u][v] = uv; directed[v][u] = vu;
    }
    int64_t answers[MAX_Q];
    int answer_count = 0;
    for (int i = 0; i < q; ++i) {
        int at = operations + 5 * i;
        int kind = (int)input[at], v = (int)input[at + 1], p = (int)input[at + 2];
        int a = (int)input[at + 3], b = (int)input[at + 4];
        if (kind == 0) {
            int uv = directed[v][p], vu = directed[p][v];
            if (uv < 0 || vu < 0 || !cut_tours(&tour, uv, vu)) return -1;
            directed[v][p] = directed[p][v] = -1;
            if (!link_tours(&tour, markers, a, b, &uv, &vu)) return -1;
            directed[a][b] = uv; directed[b][a] = vu;
        } else if (kind == 1) {
            int64_t ignored = 0;
            if (!side_operation(&tour, directed[p][v], directed[v][p], true, a, &ignored)) return -1;
        } else {
            int64_t answer = 0;
            if (!side_operation(&tour, directed[p][v], directed[v][p], false, 0, &answer)) return -1;
            answers[answer_count++] = answer;
        }
    }
    for (int i = 0; i < answer_count; ++i) put_i64_le(output, (size_t)i * 8, answers[i]);
    return (int64_t)output_bytes;
}
