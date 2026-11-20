/* Boykov–Kolmogorov maximum flow with reusable search trees and orphan adoption. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr int bk_n = 8;
constexpr int bk_free = 0;
constexpr int bk_source = 1;
constexpr int bk_sink = 2;

std::int64_t tree_capacity(const std::int64_t* residual, int kind, int parent, int child) {
    return kind == bk_source ? residual[parent * bk_n + child]
                             : residual[child * bk_n + parent];
}

bool has_terminal_origin(int node, int kind, int root, int forbidden,
                         const int* tree, const int* parent,
                         const std::int64_t* residual, int n) {
    bool seen[bk_n]{};
    while (node != root) {
        if (node < 0 || node >= n || node == forbidden || seen[node] || tree[node] != kind)
            return false;
        seen[node] = true;
        int p = parent[node];
        if (p < 0 || p >= n || tree_capacity(residual, kind, p, node) <= 0) return false;
        node = p;
    }
    return tree[root] == kind && root != forbidden;
}

void enqueue_active(int node, int* queue, int& tail, int& count, bool* active) {
    if (active[node]) return;
    queue[tail] = node;
    tail = (tail + 1) % bk_n;
    ++count;
    active[node] = true;
}

int dequeue_active(int* queue, int& head, int& count, bool* active) {
    int node = queue[head];
    head = (head + 1) % bk_n;
    --count;
    active[node] = false;
    return node;
}

void remove_active(int target, int* queue, int& head, int& tail, int& count, bool* active) {
    int kept[bk_n];
    int kept_count = 0;
    for (int i = 0; i < count; ++i) {
        int node = queue[(head + i) % bk_n];
        if (node != target) kept[kept_count++] = node;
    }
    for (int i = 0; i < kept_count; ++i) queue[i] = kept[i];
    head = 0;
    count = kept_count;
    tail = kept_count % bk_n;
    active[target] = false;
}

void enqueue_orphan(int node, int* queue, int& tail, int& count, bool* pending) {
    if (pending[node]) return;
    queue[tail] = node;
    tail = (tail + 1) % bk_n;
    ++count;
    pending[node] = true;
}

int dequeue_orphan(int* queue, int& head, int& count, bool* pending) {
    int node = queue[head];
    head = (head + 1) % bk_n;
    --count;
    pending[node] = false;
    return node;
}
}

extern "C" std::int64_t boykov_kolmogorov_maxflow(const std::int64_t* input,
                                                    std::size_t length) noexcept {
    if (!input || length < 4) return -1;
    const std::int64_t raw_n = input[0], raw_m = input[1], raw_s = input[2], raw_t = input[3];
    if (raw_n < 2 || raw_n > bk_n || raw_m < 0 || raw_m > 16 ||
        raw_s < 0 || raw_s >= raw_n || raw_t < 0 || raw_t >= raw_n || raw_s == raw_t)
        return -1;
    const int n = static_cast<int>(raw_n), m = static_cast<int>(raw_m);
    const int source = static_cast<int>(raw_s), sink = static_cast<int>(raw_t);
    if (length != static_cast<std::size_t>(4 + 3 * m)) return -1;

    std::int64_t residual[bk_n * bk_n]{};
    for (int i = 0; i < m; ++i) {
        const std::int64_t u = input[4 + 3 * i], v = input[5 + 3 * i], capacity = input[6 + 3 * i];
        if (u < 0 || u >= n || v < 0 || v >= n || u == v || capacity < 0 || capacity > 15)
            return -1;
        residual[static_cast<int>(u) * bk_n + static_cast<int>(v)] += capacity;
    }

    int tree[bk_n]{}, parent[bk_n];
    for (int v = 0; v < bk_n; ++v) parent[v] = -1;
    tree[source] = bk_source;
    tree[sink] = bk_sink;

    int active_queue[bk_n], active_head = 0, active_tail = 0, active_count = 0;
    bool active[bk_n]{};
    enqueue_active(source, active_queue, active_tail, active_count, active);
    enqueue_active(sink, active_queue, active_tail, active_count, active);
    int orphan_queue[bk_n], orphan_head = 0, orphan_tail = 0, orphan_count = 0;
    bool orphan_pending[bk_n]{};
    std::int64_t flow = 0;

    while (active_count > 0) {
        int bridge_source = -1, bridge_sink = -1;
        while (active_count > 0 && bridge_source < 0) {
            const int u = dequeue_active(active_queue, active_head, active_count, active);
            const int kind = tree[u];
            for (int v = 0; v < n; ++v) {
                const std::int64_t capacity = kind == bk_source
                    ? residual[u * bk_n + v] : residual[v * bk_n + u];
                if (capacity <= 0) continue;
                if (tree[v] == bk_free) {
                    tree[v] = kind;
                    parent[v] = u;
                    enqueue_active(v, active_queue, active_tail, active_count, active);
                } else if (tree[v] != kind) {
                    if (kind == bk_source) {
                        bridge_source = u;
                        bridge_sink = v;
                    } else {
                        bridge_source = v;
                        bridge_sink = u;
                    }
                    enqueue_active(u, active_queue, active_tail, active_count, active);
                    break;
                }
            }
        }
        if (bridge_source < 0) break;

        int reverse_source[bk_n], source_count = 0;
        for (int v = bridge_source; v >= 0; v = parent[v]) {
            if (source_count >= bk_n) return -1;
            reverse_source[source_count++] = v;
        }
        if (reverse_source[source_count - 1] != source) return -1;
        int path[bk_n + 1], path_count = 0;
        for (int i = source_count - 1; i >= 0; --i) path[path_count++] = reverse_source[i];
        path[path_count++] = bridge_sink;
        for (int v = parent[bridge_sink]; v >= 0; v = parent[v]) {
            if (path_count >= bk_n + 1) return -1;
            path[path_count++] = v;
        }
        if (path[path_count - 1] != sink) return -1;

        std::int64_t bottleneck = INT64_MAX;
        for (int i = 0; i + 1 < path_count; ++i) {
            const std::int64_t capacity = residual[path[i] * bk_n + path[i + 1]];
            if (capacity <= 0) return -1;
            if (capacity < bottleneck) bottleneck = capacity;
        }
        for (int i = 0; i + 1 < path_count; ++i) {
            const int u = path[i], v = path[i + 1];
            residual[u * bk_n + v] -= bottleneck;
            residual[v * bk_n + u] += bottleneck;
        }
        flow += bottleneck;

        for (int i = 0; i + 1 < path_count; ++i) {
            const int left = path[i], right = path[i + 1];
            if (tree[left] == bk_source && tree[right] == bk_source && parent[right] == left &&
                residual[left * bk_n + right] == 0) {
                parent[right] = -1;
                enqueue_orphan(right, orphan_queue, orphan_tail, orphan_count, orphan_pending);
            } else if (tree[left] == bk_sink && tree[right] == bk_sink && parent[left] == right &&
                       residual[left * bk_n + right] == 0) {
                parent[left] = -1;
                enqueue_orphan(left, orphan_queue, orphan_tail, orphan_count, orphan_pending);
            }
        }

        while (orphan_count > 0) {
            const int orphan = dequeue_orphan(orphan_queue, orphan_head, orphan_count, orphan_pending);
            const int kind = tree[orphan];
            if (kind == bk_free) continue;
            const int root = kind == bk_source ? source : sink;
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
                    enqueue_active(neighbor, active_queue, active_tail, active_count, active);
            }
            for (int child = 0; child < n; ++child) {
                if (parent[child] == orphan) {
                    parent[child] = -1;
                    enqueue_orphan(child, orphan_queue, orphan_tail, orphan_count, orphan_pending);
                }
            }
            tree[orphan] = bk_free;
            parent[orphan] = -1;
            remove_active(orphan, active_queue, active_head, active_tail, active_count, active);
        }
    }
    return flow;
}
