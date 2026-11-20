module boykov_kolmogorov_maxflow;

const usz BK_N = 8;
const int BK_FREE = 0;
const int BK_SOURCE = 1;
const int BK_SINK = 2;

fn long tree_capacity(long* residual, int kind, usz parent, usz child) {
    if (kind == BK_SOURCE) return residual[parent * BK_N + child];
    return residual[child * BK_N + parent];
}

fn bool has_terminal_origin(usz node, int kind, usz root, usz forbidden,
                            int* tree, int* parent, long* residual, usz n) {
    bool[BK_N] seen = {};
    while (node != root) {
        if (node >= n || node == forbidden || seen[node] || tree[node] != kind) return false;
        seen[node] = true;
        int p = parent[node];
        if (p < 0 || (usz)p >= n || tree_capacity(residual, kind, (usz)p, node) <= 0) return false;
        node = (usz)p;
    }
    return tree[root] == kind && root != forbidden;
}

fn void enqueue_active(usz node, usz* queue, usz* tail, usz* count, bool* active) {
    if (active[node]) return;
    queue[tail[0]] = node;
    tail[0] = (tail[0] + 1) % BK_N;
    count[0]++;
    active[node] = true;
}

fn usz dequeue_active(usz* queue, usz* head, usz* count, bool* active) {
    usz node = queue[head[0]];
    head[0] = (head[0] + 1) % BK_N;
    count[0]--;
    active[node] = false;
    return node;
}

fn void remove_active(usz target, usz* queue, usz* head, usz* tail,
                      usz* count, bool* active) {
    usz[BK_N] kept = {};
    usz kept_count = 0;
    for (usz i = 0; i < count[0]; i++) {
        usz node = queue[(head[0] + i) % BK_N];
        if (node != target) kept[kept_count++] = node;
    }
    for (usz i = 0; i < kept_count; i++) queue[i] = kept[i];
    head[0] = 0;
    count[0] = kept_count;
    tail[0] = kept_count % BK_N;
    active[target] = false;
}

fn void enqueue_orphan(usz node, usz* queue, usz* tail, usz* count, bool* pending) {
    if (pending[node]) return;
    queue[tail[0]] = node;
    tail[0] = (tail[0] + 1) % BK_N;
    count[0]++;
    pending[node] = true;
}

fn usz dequeue_orphan(usz* queue, usz* head, usz* count, bool* pending) {
    usz node = queue[head[0]];
    head[0] = (head[0] + 1) % BK_N;
    count[0]--;
    pending[node] = false;
    return node;
}

fn long boykov_kolmogorov_maxflow(long* input, usz length)
        @export("boykov_kolmogorov_maxflow") {
    if (input == null || length < 4) return -1;
    long raw_n = input[0], raw_m = input[1], raw_s = input[2], raw_t = input[3];
    if (raw_n < 2 || raw_n > (long)BK_N || raw_m < 0 || raw_m > 16 ||
        raw_s < 0 || raw_s >= raw_n || raw_t < 0 || raw_t >= raw_n || raw_s == raw_t)
        return -1;
    usz n = (usz)raw_n, m = (usz)raw_m, source = (usz)raw_s, sink = (usz)raw_t;
    if (length != 4 + 3 * m) return -1;

    long[BK_N * BK_N] residual = {};
    for (usz i = 0; i < m; i++) {
        long raw_u = input[4 + 3 * i], raw_v = input[5 + 3 * i], capacity = input[6 + 3 * i];
        if (raw_u < 0 || raw_u >= raw_n || raw_v < 0 || raw_v >= raw_n ||
            raw_u == raw_v || capacity < 0 || capacity > 15) return -1;
        usz u = (usz)raw_u, v = (usz)raw_v;
        residual[u * BK_N + v] += capacity;
    }

    int[BK_N] tree = {};
    int[BK_N] parent;
    for (usz v = 0; v < BK_N; v++) parent[v] = -1;
    tree[source] = BK_SOURCE;
    tree[sink] = BK_SINK;

    usz[BK_N] active_queue;
    usz active_head = 0, active_tail = 0, active_count = 0;
    bool[BK_N] active = {};
    enqueue_active(source, &active_queue[0], &active_tail, &active_count, &active[0]);
    enqueue_active(sink, &active_queue[0], &active_tail, &active_count, &active[0]);
    usz[BK_N] orphan_queue;
    usz orphan_head = 0, orphan_tail = 0, orphan_count = 0;
    bool[BK_N] orphan_pending = {};
    long flow = 0;

    while (active_count > 0) {
        int bridge_source = -1, bridge_sink = -1;
        while (active_count > 0 && bridge_source < 0) {
            usz u = dequeue_active(&active_queue[0], &active_head, &active_count, &active[0]);
            int kind = tree[u];
            for (usz v = 0; v < n; v++) {
                long capacity = kind == BK_SOURCE
                    ? residual[u * BK_N + v] : residual[v * BK_N + u];
                if (capacity <= 0) continue;
                if (tree[v] == BK_FREE) {
                    tree[v] = kind;
                    parent[v] = (int)u;
                    enqueue_active(v, &active_queue[0], &active_tail, &active_count, &active[0]);
                } else if (tree[v] != kind) {
                    if (kind == BK_SOURCE) {
                        bridge_source = (int)u;
                        bridge_sink = (int)v;
                    } else {
                        bridge_source = (int)v;
                        bridge_sink = (int)u;
                    }
                    enqueue_active(u, &active_queue[0], &active_tail, &active_count, &active[0]);
                    break;
                }
            }
        }
        if (bridge_source < 0) break;

        int[BK_N] reverse_source;
        usz source_count = 0;
        for (int v = bridge_source; v >= 0; v = parent[v]) {
            if (source_count >= BK_N) return -1;
            reverse_source[source_count++] = v;
        }
        if (reverse_source[source_count - 1] != (int)source) return -1;
        int[BK_N + 1] path;
        usz path_count = 0;
        for (usz i = source_count; i > 0; i--) path[path_count++] = reverse_source[i - 1];
        path[path_count++] = bridge_sink;
        for (int v = parent[bridge_sink]; v >= 0; v = parent[v]) {
            if (path_count >= BK_N + 1) return -1;
            path[path_count++] = v;
        }
        if (path[path_count - 1] != (int)sink) return -1;

        long bottleneck = 241;
        for (usz i = 0; i + 1 < path_count; i++) {
            long capacity = residual[(usz)path[i] * BK_N + (usz)path[i + 1]];
            if (capacity <= 0) return -1;
            if (capacity < bottleneck) bottleneck = capacity;
        }
        for (usz i = 0; i + 1 < path_count; i++) {
            usz u = (usz)path[i], v = (usz)path[i + 1];
            residual[u * BK_N + v] -= bottleneck;
            residual[v * BK_N + u] += bottleneck;
        }
        flow += bottleneck;

        for (usz i = 0; i + 1 < path_count; i++) {
            int left = path[i], right = path[i + 1];
            if (tree[left] == BK_SOURCE && tree[right] == BK_SOURCE && parent[right] == left &&
                residual[(usz)left * BK_N + (usz)right] == 0) {
                parent[right] = -1;
                enqueue_orphan((usz)right, &orphan_queue[0], &orphan_tail, &orphan_count,
                               &orphan_pending[0]);
            } else if (tree[left] == BK_SINK && tree[right] == BK_SINK && parent[left] == right &&
                       residual[(usz)left * BK_N + (usz)right] == 0) {
                parent[left] = -1;
                enqueue_orphan((usz)left, &orphan_queue[0], &orphan_tail, &orphan_count,
                               &orphan_pending[0]);
            }
        }

        while (orphan_count > 0) {
            usz orphan = dequeue_orphan(&orphan_queue[0], &orphan_head, &orphan_count,
                                        &orphan_pending[0]);
            int kind = tree[orphan];
            if (kind == BK_FREE) continue;
            usz root = kind == BK_SOURCE ? source : sink;
            int replacement = -1;
            for (usz candidate = 0; candidate < n; candidate++) {
                if (candidate != orphan && tree[candidate] == kind &&
                    tree_capacity(&residual[0], kind, candidate, orphan) > 0 &&
                    has_terminal_origin(candidate, kind, root, orphan, &tree[0], &parent[0],
                                        &residual[0], n)) {
                    replacement = (int)candidate;
                    break;
                }
            }
            if (replacement >= 0) {
                parent[orphan] = replacement;
                continue;
            }

            for (usz neighbor = 0; neighbor < n; neighbor++) {
                if (neighbor != orphan && tree[neighbor] == kind &&
                    tree_capacity(&residual[0], kind, neighbor, orphan) > 0)
                    enqueue_active(neighbor, &active_queue[0], &active_tail, &active_count, &active[0]);
            }
            for (usz child = 0; child < n; child++) {
                if (parent[child] == (int)orphan) {
                    parent[child] = -1;
                    enqueue_orphan(child, &orphan_queue[0], &orphan_tail, &orphan_count,
                                   &orphan_pending[0]);
                }
            }
            tree[orphan] = BK_FREE;
            parent[orphan] = -1;
            remove_active(orphan, &active_queue[0], &active_head, &active_tail, &active_count,
                          &active[0]);
        }
    }
    return flow;
}
