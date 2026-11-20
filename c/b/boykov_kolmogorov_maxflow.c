/* Boykov–Kolmogorov maximum flow with reusable search trees and orphan adoption. */
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define BK_N 8
#define BK_FREE 0
#define BK_SOURCE 1
#define BK_SINK 2

static int64_t tree_capacity(const int64_t *residual, int kind, int parent, int child)
{
    return kind == BK_SOURCE ? residual[parent * BK_N + child]
                             : residual[child * BK_N + parent];
}

static bool has_terminal_origin(int node, int kind, int root, int forbidden,
                                const int *tree, const int *parent,
                                const int64_t *residual, int n)
{
    bool seen[BK_N] = {false};
    while (node != root) {
        if (node < 0 || node >= n || node == forbidden || seen[node] || tree[node] != kind)
            return false;
        seen[node] = true;
        int p = parent[node];
        if (p < 0 || p >= n || tree_capacity(residual, kind, p, node) <= 0)
            return false;
        node = p;
    }
    return tree[root] == kind && root != forbidden;
}

static void enqueue_active(int node, int *queue, int *tail, int *count, bool *active)
{
    if (active[node]) return;
    queue[*tail] = node;
    *tail = (*tail + 1) % BK_N;
    (*count)++;
    active[node] = true;
}

static int dequeue_active(int *queue, int *head, int *count, bool *active)
{
    int node = queue[*head];
    *head = (*head + 1) % BK_N;
    (*count)--;
    active[node] = false;
    return node;
}

static void remove_active(int target, int *queue, int *head, int *tail,
                          int *count, bool *active)
{
    int kept[BK_N];
    int kept_count = 0;
    for (int i = 0; i < *count; ++i) {
        int node = queue[(*head + i) % BK_N];
        if (node != target) kept[kept_count++] = node;
    }
    for (int i = 0; i < kept_count; ++i) queue[i] = kept[i];
    *head = 0;
    *count = kept_count;
    *tail = kept_count % BK_N;
    active[target] = false;
}

static void enqueue_orphan(int node, int *queue, int *tail, int *count, bool *pending)
{
    if (pending[node]) return;
    queue[*tail] = node;
    *tail = (*tail + 1) % BK_N;
    (*count)++;
    pending[node] = true;
}

static int dequeue_orphan(int *queue, int *head, int *count, bool *pending)
{
    int node = queue[*head];
    *head = (*head + 1) % BK_N;
    (*count)--;
    pending[node] = false;
    return node;
}

int64_t boykov_kolmogorov_maxflow(const int64_t *input, size_t length)
{
    if (!input || length < 4) return -1;
    int64_t raw_n = input[0], raw_m = input[1], raw_s = input[2], raw_t = input[3];
    if (raw_n < 2 || raw_n > BK_N || raw_m < 0 || raw_m > 16 ||
        raw_s < 0 || raw_s >= raw_n || raw_t < 0 || raw_t >= raw_n || raw_s == raw_t)
        return -1;
    int n = (int)raw_n, m = (int)raw_m, source = (int)raw_s, sink = (int)raw_t;
    if (length != (size_t)(4 + 3 * m)) return -1;

    int64_t residual[BK_N * BK_N] = {0};
    for (int i = 0; i < m; ++i) {
        int64_t u = input[4 + 3 * i], v = input[5 + 3 * i], capacity = input[6 + 3 * i];
        if (u < 0 || u >= n || v < 0 || v >= n || u == v || capacity < 0 || capacity > 15)
            return -1;
        residual[(int)u * BK_N + (int)v] += capacity;
    }

    int tree[BK_N] = {0}, parent[BK_N];
    for (int v = 0; v < BK_N; ++v) parent[v] = -1;
    tree[source] = BK_SOURCE;
    tree[sink] = BK_SINK;

    int active_queue[BK_N], active_head = 0, active_tail = 0, active_count = 0;
    bool active[BK_N] = {false};
    enqueue_active(source, active_queue, &active_tail, &active_count, active);
    enqueue_active(sink, active_queue, &active_tail, &active_count, active);

    int orphan_queue[BK_N], orphan_head = 0, orphan_tail = 0, orphan_count = 0;
    bool orphan_pending[BK_N] = {false};
    int64_t flow = 0;

    while (active_count > 0) {
        int bridge_source = -1, bridge_sink = -1;
        while (active_count > 0 && bridge_source < 0) {
            int u = dequeue_active(active_queue, &active_head, &active_count, active);
            int kind = tree[u];
            for (int v = 0; v < n; ++v) {
                int64_t capacity = kind == BK_SOURCE
                    ? residual[u * BK_N + v] : residual[v * BK_N + u];
                if (capacity <= 0) continue;
                if (tree[v] == BK_FREE) {
                    tree[v] = kind;
                    parent[v] = u;
                    enqueue_active(v, active_queue, &active_tail, &active_count, active);
                } else if (tree[v] != kind) {
                    if (kind == BK_SOURCE) {
                        bridge_source = u;
                        bridge_sink = v;
                    } else {
                        bridge_source = v;
                        bridge_sink = u;
                    }
                    enqueue_active(u, active_queue, &active_tail, &active_count, active);
                    break;
                }
            }
        }
        if (bridge_source < 0) break;

        int reverse_source[BK_N], source_count = 0;
        for (int v = bridge_source; v >= 0; v = parent[v]) {
            if (source_count >= BK_N) return -1;
            reverse_source[source_count++] = v;
        }
        if (reverse_source[source_count - 1] != source) return -1;
        int path[BK_N + 1], path_count = 0;
        for (int i = source_count - 1; i >= 0; --i) path[path_count++] = reverse_source[i];
        path[path_count++] = bridge_sink;
        for (int v = parent[bridge_sink]; v >= 0; v = parent[v]) {
            if (path_count >= BK_N + 1) return -1;
            path[path_count++] = v;
        }
        if (path[path_count - 1] != sink) return -1;

        int64_t bottleneck = INT64_MAX;
        for (int i = 0; i + 1 < path_count; ++i) {
            int64_t capacity = residual[path[i] * BK_N + path[i + 1]];
            if (capacity <= 0) return -1;
            if (capacity < bottleneck) bottleneck = capacity;
        }
        for (int i = 0; i + 1 < path_count; ++i) {
            int u = path[i], v = path[i + 1];
            residual[u * BK_N + v] -= bottleneck;
            residual[v * BK_N + u] += bottleneck;
        }
        flow += bottleneck;

        for (int i = 0; i + 1 < path_count; ++i) {
            int left = path[i], right = path[i + 1];
            if (tree[left] == BK_SOURCE && tree[right] == BK_SOURCE && parent[right] == left &&
                residual[left * BK_N + right] == 0) {
                parent[right] = -1;
                enqueue_orphan(right, orphan_queue, &orphan_tail, &orphan_count, orphan_pending);
            } else if (tree[left] == BK_SINK && tree[right] == BK_SINK && parent[left] == right &&
                       residual[left * BK_N + right] == 0) {
                parent[left] = -1;
                enqueue_orphan(left, orphan_queue, &orphan_tail, &orphan_count, orphan_pending);
            }
        }

        while (orphan_count > 0) {
            int orphan = dequeue_orphan(orphan_queue, &orphan_head, &orphan_count, orphan_pending);
            int kind = tree[orphan];
            if (kind == BK_FREE) continue;
            int root = kind == BK_SOURCE ? source : sink;
            int replacement = -1;
            for (int candidate = 0; candidate < n; ++candidate) {
                if (candidate != orphan && tree[candidate] == kind &&
                    tree_capacity(residual, kind, candidate, orphan) > 0 &&
                    has_terminal_origin(candidate, kind, root, orphan, tree, parent, residual, n)) {
                    replacement = candidate;
                    break;
                }
            }
            if (replacement >= 0) {
                parent[orphan] = replacement;
                continue;
            }

            for (int neighbor = 0; neighbor < n; ++neighbor) {
                if (neighbor != orphan && tree[neighbor] == kind &&
                    tree_capacity(residual, kind, neighbor, orphan) > 0)
                    enqueue_active(neighbor, active_queue, &active_tail, &active_count, active);
            }
            for (int child = 0; child < n; ++child) {
                if (parent[child] == orphan) {
                    parent[child] = -1;
                    enqueue_orphan(child, orphan_queue, &orphan_tail, &orphan_count, orphan_pending);
                }
            }
            tree[orphan] = BK_FREE;
            parent[orphan] = -1;
            remove_active(orphan, active_queue, &active_head, &active_tail,
                          &active_count, active);
        }
    }
    return flow;
}
