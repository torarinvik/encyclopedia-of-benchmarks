// Clean-room bounded rotation-system planarity recognizer.
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t rotation_system_planarity_test(const std::int64_t *input, std::size_t length) {
    constexpr int MAX_N = 6, MAX_M = 15, MAX_DARTS = 30;
    if (input == nullptr || length < 2 || length > 33) return -1;
    const auto n64 = input[0], m64 = input[1];
    if (n64 < 1 || n64 > MAX_N || m64 < 0 || m64 > MAX_M || length != 2 + 2 * static_cast<std::size_t>(m64)) return -1;
    const int n = static_cast<int>(n64), m = static_cast<int>(m64);
    bool adjacent[MAX_N][MAX_N]{};
    int edge_u[MAX_M]{}, edge_v[MAX_M]{};
    for (int e = 0; e < m; ++e) {
        const auto u64 = input[2 + 2 * static_cast<std::size_t>(e)];
        const auto v64 = input[3 + 2 * static_cast<std::size_t>(e)];
        if (u64 < 0 || u64 >= v64 || v64 >= n64) return -1;
        const int u = static_cast<int>(u64), v = static_cast<int>(v64);
        if (adjacent[u][v]) return -1;
        adjacent[u][v] = adjacent[v][u] = true;
        edge_u[e] = u; edge_v[e] = v;
    }
    if (n >= 3 && m > 3 * n - 6) return 0;

    int edge_id[MAX_N][MAX_N];
    int neighbors[MAX_N][MAX_N]{}, degree[MAX_N]{};
    for (int u = 0; u < n; ++u) for (int v = 0; v < n; ++v) edge_id[u][v] = -1;
    for (int e = 0; e < m; ++e) edge_id[edge_u[e]][edge_v[e]] = edge_id[edge_v[e]][edge_u[e]] = e;
    for (int u = 0; u < n; ++u) for (int v = 0; v < n; ++v) if (adjacent[u][v]) neighbors[u][degree[u]++] = v;

    int component[MAX_N];
    int component_vertices[MAX_N][MAX_N]{};
    int component_size[MAX_N]{};
    for (int v = 0; v < n; ++v) component[v] = -1;
    int component_count = 0;
    for (int root = 0; root < n; ++root) if (component[root] == -1) {
        const int id = component_count++;
        int queue[MAX_N], head = 0, tail = 0;
        component[root] = id; queue[tail++] = root;
        while (head < tail) {
            const int here = queue[head++];
            component_vertices[id][component_size[id]++] = here;
            for (int there = 0; there < n; ++there) if (adjacent[here][there] && component[there] == -1) {
                component[there] = id; queue[tail++] = there;
            }
        }
    }
    for (int cid = 0; cid < component_count; ++cid) {
        int component_edges = 0;
        for (int e = 0; e < m; ++e) if (component[edge_u[e]] == cid) ++component_edges;
        if (component_size[cid] >= 3 && component_edges > 3 * component_size[cid] - 6) return 0;
        if (component_size[cid] == 1) continue;
        int rotation[MAX_N][MAX_N]{};
        for (int i = 0; i < component_size[cid]; ++i) {
            const int v = component_vertices[cid][i];
            for (int j = 0; j < degree[v]; ++j) rotation[v][j] = neighbors[v][j];
        }
        bool found = false, done = false;
        while (!found && !done) {
            int successor[MAX_DARTS];
            for (int d = 0; d < 2 * m; ++d) successor[d] = -1;
            for (int i = 0; i < component_size[cid]; ++i) {
                const int v = component_vertices[cid][i], d = degree[v];
                for (int j = 0; j < d; ++j) {
                    const int next = (j + 1) % d;
                    const int e = edge_id[v][rotation[v][j]], next_e = edge_id[v][rotation[v][next]];
                    successor[2 * e + (edge_u[e] == v ? 0 : 1)] = 2 * next_e + (edge_u[next_e] == v ? 0 : 1);
                }
            }
            bool used[MAX_DARTS]{};
            int faces = 0;
            for (int e = 0; e < m; ++e) if (component[edge_u[e]] == cid) {
                for (int orientation = 0; orientation < 2; ++orientation) {
                    int dart = 2 * e + orientation;
                    if (used[dart]) continue;
                    ++faces;
                    while (!used[dart]) { used[dart] = true; dart = successor[dart ^ 1]; }
                }
            }
            if (component_size[cid] - component_edges + faces == 2) { found = true; break; }
            int position = component_size[cid] - 1;
            bool advanced = false;
            while (position >= 0 && !advanced) {
                const int v = component_vertices[cid][position], d = degree[v];
                int pivot = d - 2;
                while (pivot >= 1 && rotation[v][pivot] >= rotation[v][pivot + 1]) --pivot;
                if (pivot >= 1) {
                    int swap_at = d - 1;
                    while (rotation[v][swap_at] <= rotation[v][pivot]) --swap_at;
                    const int temp = rotation[v][pivot]; rotation[v][pivot] = rotation[v][swap_at]; rotation[v][swap_at] = temp;
                    int left = pivot + 1, right = d - 1;
                    while (left < right) { const int value = rotation[v][left]; rotation[v][left] = rotation[v][right]; rotation[v][right] = value; ++left; --right; }
                    advanced = true;
                } else {
                    for (int j = 0; j < d; ++j) rotation[v][j] = neighbors[v][j];
                    --position;
                }
            }
            if (!advanced) done = true;
        }
        if (!found) return 0;
    }
    return 1;
}
