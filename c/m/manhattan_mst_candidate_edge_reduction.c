#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>

enum { MAX_N = 31, MAX_CANDIDATES = 4 * MAX_N };

typedef struct { int x, y, id; } Point;
typedef struct { int u, v, weight; } Edge;

static int point_sum_compare(const void *left_raw, const void *right_raw) {
    const Point left = *(const Point *)left_raw;
    const Point right = *(const Point *)right_raw;
    const int left_sum = left.x + left.y, right_sum = right.x + right.y;
    if (left_sum != right_sum) return left_sum < right_sum ? -1 : 1;
    if (left.x != right.x) return left.x < right.x ? -1 : 1;
    if (left.y != right.y) return left.y < right.y ? -1 : 1;
    return left.id < right.id ? -1 : left.id > right.id;
}

static int point_x_compare(const void *left_raw, const void *right_raw) {
    const Point left = *(const Point *)left_raw;
    const Point right = *(const Point *)right_raw;
    if (left.x != right.x) return left.x < right.x ? -1 : 1;
    if (left.y != right.y) return left.y < right.y ? -1 : 1;
    return left.id < right.id ? -1 : left.id > right.id;
}

static void fenwick_add(int tree[MAX_N + 1], int n, int index, int delta) {
    for (int at = index + 1; at <= n; at += at & -at) tree[at] += delta;
}

static int fenwick_prefix(const int tree[MAX_N + 1], int count) {
    int result = 0;
    for (int at = count; at > 0; at -= at & -at) result += tree[at];
    return result;
}

static int fenwick_kth(const int tree[MAX_N + 1], int n, int rank) {
    int index = 0, accumulated = 0, step = 1;
    while (step * 2 <= n) step *= 2;
    for (; step > 0; step /= 2) {
        const int next = index + step;
        if (next <= n && accumulated + tree[next] < rank) {
            index = next;
            accumulated += tree[next];
        }
    }
    return index;
}

static void append_edge(Edge edges[MAX_CANDIDATES], int *edge_count,
                        const Point original[MAX_N], int u, int v) {
    const int dx = original[u].x >= original[v].x ? original[u].x - original[v].x : original[v].x - original[u].x;
    const int dy = original[u].y >= original[v].y ? original[u].y - original[v].y : original[v].y - original[u].y;
    edges[*edge_count] = (Edge){u, v, dx + dy};
    ++(*edge_count);
}

static int edge_compare(const void *left_raw, const void *right_raw) {
    const Edge left = *(const Edge *)left_raw;
    const Edge right = *(const Edge *)right_raw;
    if (left.weight != right.weight) return left.weight < right.weight ? -1 : 1;
    const int left_u = left.u < left.v ? left.u : left.v;
    const int left_v = left.u < left.v ? left.v : left.u;
    const int right_u = right.u < right.v ? right.u : right.v;
    const int right_v = right.u < right.v ? right.v : right.u;
    if (left_u != right_u) return left_u < right_u ? -1 : 1;
    return left_v < right_v ? -1 : left_v > right_v;
}

static int find_root(int parent[MAX_N], int value) {
    int root = value;
    while (parent[root] != root) root = parent[root];
    while (parent[value] != value) {
        const int next = parent[value];
        parent[value] = root;
        value = next;
    }
    return root;
}

int64_t manhattan_mst_candidate_edge_reduction(const int64_t *input, size_t length) {
    if (input == NULL || length < 1 || length > 1 + 2 * MAX_N) return -1;
    if (input[0] < 0 || input[0] > MAX_N || length != 1 + 2 * (size_t)input[0]) return -1;
    const int n = (int)input[0];
    Point points[MAX_N], original[MAX_N];
    uint64_t seen_x[32] = {0}, seen_y[32] = {0};
    for (int i = 0; i < n; ++i) {
        const int64_t x = input[1 + 2 * (size_t)i], y = input[2 + 2 * (size_t)i];
        if (x < -1000 || x > 1000 || y < -1000 || y > 1000) return -1;
        const unsigned x_index = (unsigned)((int)x + 1000);
        const unsigned y_index = (unsigned)((int)y + 1000);
        const unsigned x_word = x_index >> 6, y_word = y_index >> 6;
        const uint64_t x_mask = UINT64_C(1) << (x_index & 63), y_mask = UINT64_C(1) << (y_index & 63);
        if ((seen_x[x_word] & x_mask) != 0 || (seen_y[y_word] & y_mask) != 0) return -1;
        seen_x[x_word] |= x_mask;
        seen_y[y_word] |= y_mask;
        points[i] = (Point){(int)x, (int)y, i};
        original[i] = points[i];
    }
    if (n < 2) return 0;

    Edge candidates[MAX_CANDIDATES];
    int candidate_count = 0;
    for (int direction = 0; direction < 4; ++direction) {
        Point by_sum[MAX_N], by_x[MAX_N];
        int rank_by_id[MAX_N];
        for (int i = 0; i < n; ++i) by_sum[i] = by_x[i] = points[i];
        qsort(by_sum, (size_t)n, sizeof(by_sum[0]), point_sum_compare);
        qsort(by_x, (size_t)n, sizeof(by_x[0]), point_x_compare);
        for (int rank = 0; rank < n; ++rank) rank_by_id[by_x[rank].id] = rank;

        int active[MAX_N + 1] = {0};
        for (int i = 0; i < n; ++i) {
            const Point current = by_sum[i];
            const int current_rank = rank_by_id[current.id];
            int active_before = fenwick_prefix(active, current_rank + 1);
            while (active_before > 0) {
                const int candidate_rank = fenwick_kth(active, n, active_before);
                const int candidate_id = by_x[candidate_rank].id;
                const Point candidate = points[candidate_id];
                if (current.x - current.y > candidate.x - candidate.y) break;
                append_edge(candidates, &candidate_count, original, current.id, candidate_id);
                fenwick_add(active, n, candidate_rank, -1);
                active_before = fenwick_prefix(active, current_rank + 1);
            }
            fenwick_add(active, n, current_rank, 1);
        }
        for (int i = 0; i < n; ++i) {
            if ((direction & 1) == 0) {
                const int old_x = points[i].x;
                points[i].x = points[i].y;
                points[i].y = old_x;
            } else {
                points[i].x = -points[i].x;
            }
        }
    }

    qsort(candidates, (size_t)candidate_count, sizeof(candidates[0]), edge_compare);

    int parent[MAX_N], component_size[MAX_N];
    for (int i = 0; i < n; ++i) parent[i] = i, component_size[i] = 1;
    int64_t total = 0;
    int accepted = 0;
    for (int i = 0; i < candidate_count && accepted < n - 1; ++i) {
        const Edge edge = candidates[i];
        const int root_u = find_root(parent, edge.u), root_v = find_root(parent, edge.v);
        if (root_u == root_v) continue;
        if (component_size[root_u] < component_size[root_v]) {
            parent[root_u] = root_v;
            component_size[root_v] += component_size[root_u];
        } else {
            parent[root_v] = root_u;
            component_size[root_u] += component_size[root_v];
        }
        total += edge.weight;
        ++accepted;
    }
    return accepted == n - 1 ? total : -1;
}
