#include <stddef.h>
#include <stdint.h>

#define ARD_N 8
#define ARD_M 12
#define ARD_K 4
#define ARD_INPUT 50

static int ard_reaches(int n, const int allowed[ARD_N][ARD_N],
                       const int64_t residual[ARD_N][ARD_N], int start,
                       const int target[ARD_N]) {
    int seen[ARD_N] = {0};
    int queue[ARD_N], head = 0, tail = 0;
    if (target[start]) return 1;
    seen[start] = 1;
    queue[tail++] = start;
    while (head < tail) {
        const int u = queue[head++];
        for (int v = 0; v < n; ++v) {
            if (seen[v] || !allowed[u][v] || residual[u][v] <= 0) continue;
            if (target[v]) return 1;
            seen[v] = 1;
            queue[tail++] = v;
        }
    }
    return 0;
}

static int ard_find_path(int n, const int in_region[ARD_N],
                         const int allowed[ARD_N][ARD_N],
                         const int64_t residual[ARD_N][ARD_N],
                         const int target[ARD_N], const int64_t excess[ARD_N],
                         int parent[ARD_N]) {
    int queue[ARD_N], head = 0, tail = 0;
    for (int v = 0; v < n; ++v) parent[v] = -1;
    for (int v = 0; v < n; ++v) {
        if (in_region[v] && excess[v] > 0) {
            parent[v] = v;
            queue[tail++] = v;
        }
    }
    while (head < tail) {
        const int u = queue[head++];
        for (int v = 0; v < n; ++v) {
            if (parent[v] >= 0 || !allowed[u][v] || residual[u][v] <= 0) continue;
            parent[v] = u;
            if (target[v]) return v;
            queue[tail++] = v;
        }
    }
    return -1;
}

static int64_t ard_discharge(int n, int region_id, int source, int sink,
                             int boundary_count, const int region[ARD_N],
                             const int64_t global_residual[ARD_N][ARD_N],
                             int64_t residual[ARD_N][ARD_N],
                             int64_t excess[ARD_N], int label[ARD_N],
                             int64_t flow_value,
                             const int boundary_by_region[ARD_K][ARD_N]) {
    int in_region[ARD_N] = {0}, external[ARD_N] = {0};
    int inside_or_terminal[ARD_N] = {0};
    int allowed[ARD_N][ARD_N] = {{0}};
    int local_residual[ARD_N][ARD_N] = {{0}};
    for (int v = 0; v < n; ++v) {
        in_region[v] = (v != source && v != sink && region[v] == region_id);
        external[v] = boundary_by_region[region_id][v];
        inside_or_terminal[v] = in_region[v] || v == source || v == sink;
    }
    for (int u = 0; u < n; ++u) for (int v = 0; v < n; ++v) {
        allowed[u][v] =
            (inside_or_terminal[u] && inside_or_terminal[v]) ||
            (in_region[u] && external[v]) || (external[u] && in_region[v]);
        if (allowed[u][v] && !(external[u] && in_region[v]))
            local_residual[u][v] = global_residual[u][v];
    }

    for (int stage = 0; stage <= boundary_count; ++stage) {
        int target[ARD_N] = {0};
        target[sink] = 1;
        for (int v = 0; v < n; ++v)
            if (external[v] && label[v] < stage) target[v] = 1;
        for (;;) {
            int parent[ARD_N];
            const int finish = ard_find_path(n, in_region, allowed,
                                             (const int64_t (*)[ARD_N])local_residual,
                                             target, excess, parent);
            if (finish < 0) break;
            int path[ARD_N], path_len = 0;
            for (int v = finish;; v = parent[v]) {
                path[path_len++] = v;
                if (parent[v] == v) break;
            }
            const int start = path[path_len - 1];
            int64_t amount = excess[start];
            for (int i = path_len - 1; i > 0; --i) {
                const int u = path[i], v = path[i - 1];
                if (local_residual[u][v] < amount) amount = local_residual[u][v];
            }
            for (int i = path_len - 1; i > 0; --i) {
                const int u = path[i], v = path[i - 1];
                local_residual[u][v] -= amount;
                local_residual[v][u] += amount;
                residual[u][v] -= amount;
                residual[v][u] += amount;
            }
            excess[start] -= amount;
            if (finish == sink) flow_value += amount;
            else excess[finish] += amount;
        }
    }

    for (int u = 0; u < n; ++u) if (in_region[u]) {
        int new_label = boundary_count;
        for (int stage = 0; stage <= boundary_count; ++stage) {
            int target[ARD_N] = {0};
            target[sink] = 1;
            for (int v = 0; v < n; ++v)
                if (external[v] && label[v] < stage) target[v] = 1;
            if (ard_reaches(n, allowed,
                            (const int64_t (*)[ARD_N])local_residual,
                            u, target)) {
                new_label = stage;
                break;
            }
        }
        if (new_label > label[u]) label[u] = new_label;
    }
    return flow_value;
}

int64_t region_discharge_path_push_relabel_maxflow(const int64_t *input,
                                                    size_t length) {
    if (input == NULL || length < 5 || length > ARD_INPUT) return -1;
    const int64_t nv = input[0], mv = input[1], kv = input[2];
    const int64_t source_v = input[3], sink_v = input[4];
    if (nv < 4 || nv > ARD_N || mv < 1 || mv > ARD_M || kv < 2 || kv > ARD_K ||
        kv > nv - 2 || source_v < 0 || source_v >= nv || sink_v < 0 ||
        sink_v >= nv || source_v == sink_v ||
        length != 5 + (size_t)nv + 3 * (size_t)mv) return -1;
    const int n = (int)nv, m = (int)mv, region_count = (int)kv;
    const int source = (int)source_v, sink = (int)sink_v;
    int region[ARD_N], seen[ARD_K] = {0};
    int64_t capacity[ARD_N][ARD_N] = {{0}};
    int64_t residual[ARD_N][ARD_N] = {{0}};
    int64_t excess[ARD_N] = {0};
    int label[ARD_N] = {0};
    int boundary_by_region[ARD_K][ARD_N] = {{0}};
    int boundary[ARD_N] = {0};
    size_t at = 5;
    for (int v = 0; v < n; ++v) {
        const int64_t raw = input[at++];
        if (v == source || v == sink) {
            if (raw != -1) return -1;
            region[v] = -1;
        } else {
            if (raw < 0 || raw >= region_count) return -1;
            region[v] = (int)raw;
            seen[region[v]] = 1;
        }
    }
    for (int b = 0; b < region_count; ++b) if (!seen[b]) return -1;
    for (int e = 0; e < m; ++e) {
        const int64_t uv = input[at++], vv = input[at++], cv = input[at++];
        if (uv < 0 || uv >= n || vv < 0 || vv >= n || uv == vv ||
            vv == source || uv == sink || cv < 0 || cv > 7) return -1;
        const int u = (int)uv, v = (int)vv;
        capacity[u][v] += cv;
        if (cv > 0 && region[u] >= 0 && region[v] >= 0 && region[u] != region[v]) {
            boundary[u] = boundary[v] = 1;
            boundary_by_region[region[u]][v] = 1;
            boundary_by_region[region[v]][u] = 1;
        }
    }
    int boundary_count = 0;
    for (int v = 0; v < n; ++v) boundary_count += boundary[v];
    if (boundary_count < 2) return -1;
    for (int u = 0; u < n; ++u) for (int v = 0; v < n; ++v)
        residual[u][v] = capacity[u][v];

    int64_t flow_value = 0;
    for (int v = 0; v < n; ++v) {
        const int64_t amount = residual[source][v];
        if (amount > 0) {
            residual[source][v] = 0;
            residual[v][source] += amount;
            if (v == sink) flow_value += amount;
            else excess[v] += amount;
        }
    }
    label[source] = boundary_count;
    const int sweep_limit = 2 * boundary_count * boundary_count + 1;
    for (int sweep = 0; sweep < sweep_limit; ++sweep) {
        for (int b = 0; b < region_count; ++b)
            flow_value = ard_discharge(n, b, source, sink, boundary_count,
                                       region, (const int64_t (*)[ARD_N])residual,
                                       residual, excess, label, flow_value,
                                       boundary_by_region);
        int active = 0;
        for (int v = 0; v < n; ++v)
            if (v != source && v != sink && excess[v] > 0 && label[v] < boundary_count)
                active = 1;
        if (!active) return flow_value;
    }
    return -1;
}
