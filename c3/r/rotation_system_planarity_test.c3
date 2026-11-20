// Clean-room bounded rotation-system planarity recognizer.
module rotation_system_planarity_test;
const usz MAX_N = 6;
const usz MAX_M = 15;
const usz MAX_DARTS = 30;

fn long rotation_system_planarity_test(long* input, usz length) @export("rotation_system_planarity_test") {
    if (input == null || length < 2 || length > 33) return -1;
    long n64 = input[0], m64 = input[1];
    if (n64 < 1 || n64 > 6 || m64 < 0 || m64 > 15 || length != 2 + 2 * (usz)m64) return -1;
    usz n = (usz)n64, m = (usz)m64;
    uint8[MAX_N * MAX_N] adjacent = zeroed;
    usz[MAX_M] edge_u, edge_v;
    for (usz e = 0; e < m; e += 1) {
        long u64 = input[2 + 2 * e], v64 = input[3 + 2 * e];
        if (u64 < 0 || u64 >= v64 || v64 >= n64) return -1;
        usz u = (usz)u64, v = (usz)v64;
        if (adjacent[u * MAX_N + v] != 0) return -1;
        adjacent[u * MAX_N + v] = 1; adjacent[v * MAX_N + u] = 1;
        edge_u[e] = u; edge_v[e] = v;
    }
    if (n >= 3 && m > 3 * n - 6) return 0;
    long[MAX_N * MAX_N] edge_id = zeroed;
    usz[MAX_N * MAX_N] neighbors = zeroed;
    usz[MAX_N] degree = zeroed;
    for (usz u = 0; u < n; u += 1) for (usz v = 0; v < n; v += 1) edge_id[u * MAX_N + v] = -1;
    for (usz e = 0; e < m; e += 1) {
        edge_id[edge_u[e] * MAX_N + edge_v[e]] = (long)e;
        edge_id[edge_v[e] * MAX_N + edge_u[e]] = (long)e;
    }
    for (usz u = 0; u < n; u += 1) for (usz v = 0; v < n; v += 1) if (adjacent[u * MAX_N + v] != 0) {
        neighbors[u * MAX_N + degree[u]] = v; degree[u] += 1;
    }
    long[MAX_N] component;
    for (usz v = 0; v < n; v += 1) component[v] = -1;
    usz[MAX_N * MAX_N] component_vertices = zeroed;
    usz[MAX_N] component_size = zeroed;
    usz component_count = 0;
    for (usz root = 0; root < n; root += 1) if (component[root] == -1) {
        usz id = component_count; component_count += 1;
        usz[MAX_N] queue;
        usz head = 0, tail = 0;
        component[root] = (long)id; queue[tail] = root; tail += 1;
        while (head < tail) {
            usz here = queue[head]; head += 1;
            component_vertices[id * MAX_N + component_size[id]] = here; component_size[id] += 1;
            for (usz there = 0; there < n; there += 1) if (adjacent[here * MAX_N + there] != 0 && component[there] == -1) {
                component[there] = (long)id; queue[tail] = there; tail += 1;
            }
        }
    }
    for (usz cid = 0; cid < component_count; cid += 1) {
        usz edge_count = 0;
        for (usz e = 0; e < m; e += 1) if (component[edge_u[e]] == (long)cid) edge_count += 1;
        if (component_size[cid] >= 3 && edge_count > 3 * component_size[cid] - 6) return 0;
        if (component_size[cid] == 1) continue;
        usz[MAX_N * MAX_N] rotation = zeroed;
        for (usz i = 0; i < component_size[cid]; i += 1) {
            usz v = component_vertices[cid * MAX_N + i];
            for (usz j = 0; j < degree[v]; j += 1) rotation[v * MAX_N + j] = neighbors[v * MAX_N + j];
        }
        bool found = false, done = false;
        while (!found && !done) {
            long[MAX_DARTS] successor;
            for (usz d = 0; d < 2 * m; d += 1) successor[d] = -1;
            for (usz i = 0; i < component_size[cid]; i += 1) {
                usz v = component_vertices[cid * MAX_N + i], d = degree[v];
                for (usz j = 0; j < d; j += 1) {
                    usz next = (j + 1) % d;
                    usz e = (usz)edge_id[v * MAX_N + rotation[v * MAX_N + j]];
                    usz next_e = (usz)edge_id[v * MAX_N + rotation[v * MAX_N + next]];
                    usz dart = 2 * e + (edge_u[e] == v ? 0 : 1);
                    usz next_dart = 2 * next_e + (edge_u[next_e] == v ? 0 : 1);
                    successor[dart] = (long)next_dart;
                }
            }
            bool[MAX_DARTS] used = zeroed;
            usz faces = 0;
            for (usz e = 0; e < m; e += 1) if (component[edge_u[e]] == (long)cid) {
                for (usz orientation = 0; orientation < 2; orientation += 1) {
                    usz dart = 2 * e + orientation;
                    if (used[dart]) continue;
                    faces += 1;
                    while (!used[dart]) { used[dart] = true; dart = (usz)successor[dart ^ 1]; }
                }
            }
            if ((long)component_size[cid] - (long)edge_count + (long)faces == 2) { found = true; break; }
            long position = (long)component_size[cid] - 1;
            bool advanced = false;
            while (position >= 0 && !advanced) {
                usz v = component_vertices[cid * MAX_N + (usz)position], d = degree[v];
                long pivot = (long)d - 2;
                while (pivot >= 1 && rotation[v * MAX_N + (usz)pivot] >= rotation[v * MAX_N + (usz)pivot + 1]) pivot -= 1;
                if (pivot >= 1) {
                    usz swap_at = d - 1;
                    while (rotation[v * MAX_N + swap_at] <= rotation[v * MAX_N + (usz)pivot]) swap_at -= 1;
                    usz temp = rotation[v * MAX_N + (usz)pivot]; rotation[v * MAX_N + (usz)pivot] = rotation[v * MAX_N + swap_at]; rotation[v * MAX_N + swap_at] = temp;
                    usz left = (usz)pivot + 1, right = d - 1;
                    while (left < right) { usz value = rotation[v * MAX_N + left]; rotation[v * MAX_N + left] = rotation[v * MAX_N + right]; rotation[v * MAX_N + right] = value; left += 1; right -= 1; }
                    advanced = true;
                } else {
                    for (usz j = 0; j < d; j += 1) rotation[v * MAX_N + j] = neighbors[v * MAX_N + j];
                    position -= 1;
                }
            }
            if (!advanced) done = true;
        }
        if (!found) return 0;
    }
    return 1;
}
