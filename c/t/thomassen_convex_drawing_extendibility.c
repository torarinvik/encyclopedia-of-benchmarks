#include <stddef.h>
#include <stdint.h>

#define TH_N 8
#define TH_M 18
#define TH_F 12
#define TH_INPUT 93
#define TH_FLOW_NODES (2 * TH_N + 2)
#define TH_DP_STATES (1 << TH_N)

static int th_connected(const uint8_t adjacency[TH_N][TH_N], int n, int removed) {
    uint8_t seen[TH_N] = {0};
    int stack[TH_N], top = 0, count = 0;
    int start = removed == 0 ? 1 : 0;
    seen[start] = 1;
    stack[top++] = start;
    while (top) {
        int u = stack[--top];
        ++count;
        for (int v = 0; v < n; ++v) {
            if (v != removed && adjacency[u][v] && !seen[v]) {
                seen[v] = 1;
                stack[top++] = v;
            }
        }
    }
    return count == n - (removed >= 0);
}

static int th_three_outer_paths(const uint8_t adjacency[TH_N][TH_N],
                                const uint8_t outer[TH_N], int n, int root) {
    int residual[TH_FLOW_NODES][TH_FLOW_NODES] = {{0}};
    int source = 2 * n, sink = source + 1, nodes = sink + 1;
    for (int v = 0; v < n; ++v)
        if (v != root) residual[2 * v][2 * v + 1] = 1;
    for (int u = 0; u < n; ++u) for (int v = u + 1; v < n; ++v) {
        if (!adjacency[u][v]) continue;
        if (u == root) residual[source][2 * v] += 1;
        else if (v == root) residual[source][2 * u] += 1;
        else {
            residual[2 * u + 1][2 * v] += 1;
            residual[2 * v + 1][2 * u] += 1;
        }
    }
    for (int v = 0; v < n; ++v)
        if (outer[v] && v != root) residual[2 * v + 1][sink] += 1;

    for (int flow = 0; flow < 3; ++flow) {
        int parent[TH_FLOW_NODES], queue[TH_FLOW_NODES], head = 0, tail = 0;
        for (int v = 0; v < nodes; ++v) parent[v] = -1;
        parent[source] = source;
        queue[tail++] = source;
        while (head < tail && parent[sink] < 0) {
            int u = queue[head++];
            for (int v = 0; v < nodes; ++v) {
                if (residual[u][v] > 0 && parent[v] < 0) {
                    parent[v] = u;
                    queue[tail++] = v;
                    if (v == sink) break;
                }
            }
        }
        if (parent[sink] < 0) return 0;
        for (int v = sink; v != source; v = parent[v]) {
            int u = parent[v];
            --residual[u][v];
            ++residual[v][u];
        }
    }
    return 1;
}

static int th_condition_three(const uint8_t inner[TH_N][TH_N],
                              const int degree[TH_N], int n) {
    int mask_size[TH_DP_STATES] = {0};
    for (int mask = 1; mask < (1 << n); ++mask)
        mask_size[mask] = mask_size[mask >> 1] + (mask & 1);
    for (int start = 0; start < n; ++start) {
        uint8_t dp[TH_DP_STATES][TH_N];
        for (int mask = 0; mask < TH_DP_STATES; ++mask)
            for (int last = 0; last < n; ++last) dp[mask][last] = UINT8_MAX;
        dp[1 << start][start] = (uint8_t)(degree[start] >= 3);
        for (int mask = 0; mask < (1 << n); ++mask) {
            if (!(mask & (1 << start))) continue;
            for (int last = start; last < n; ++last) {
                uint8_t used = dp[mask][last];
                if (used == UINT8_MAX) continue;
                if (mask_size[mask] >= 3 && inner[last][start] && used < 3) return 0;
                for (int next = start + 1; next < n; ++next) {
                    int bit = 1 << next;
                    if ((mask & bit) || !inner[last][next]) continue;
                    int candidate = used + (degree[next] >= 3);
                    int next_mask = mask | bit;
                    if (candidate < dp[next_mask][next]) dp[next_mask][next] = (uint8_t)candidate;
                }
            }
        }
    }
    return 1;
}

int64_t thomassen_convex_drawing_extendibility(const int64_t *input, size_t length) {
    if (input == NULL || length < 5 || length > TH_INPUT) return -1;
    int64_t n0 = input[0], m0 = input[1], f0 = input[2], outer0 = input[3], sides0 = input[4];
    if (n0 < 3 || n0 > TH_N || m0 < n0 || m0 > TH_M || m0 > 3 * n0 - 6 ||
        f0 < 2 || f0 > TH_F || f0 != m0 - n0 + 2 || outer0 < 0 || outer0 >= f0 ||
        sides0 < 3 || sides0 > n0) return -1;
    int n = (int)n0, m = (int)m0, f = (int)f0, outer_id = (int)outer0, side_count = (int)sides0;
    int edge_u[TH_M], edge_v[TH_M];
    uint8_t adjacency[TH_N][TH_N] = {{0}};
    for (int e = 0; e < m; ++e) {
        size_t p = 5 + (size_t)(2 * e);
        if (p + 1 >= length) return -1;
        int64_t u0 = input[p], v0 = input[p + 1];
        if (u0 < 0 || u0 >= v0 || v0 >= n) return -1;
        int u = (int)u0, v = (int)v0;
        if (adjacency[u][v] || (e > 0 && (u < edge_u[e - 1] || (u == edge_u[e - 1] && v <= edge_v[e - 1])))) return -1;
        adjacency[u][v] = adjacency[v][u] = 1;
        edge_u[e] = u; edge_v[e] = v;
    }
    int faces[TH_F][TH_N] = {{0}}, widths[TH_F] = {0};
    int dart_use[TH_N][TH_N] = {{0}};
    size_t cursor = 5 + (size_t)(2 * m);
    for (int face = 0; face < f; ++face) {
        if (cursor >= length) return -1;
        int64_t width0 = input[cursor++];
        if (width0 < 3 || width0 > n || cursor + (size_t)width0 > length) return -1;
        int width = (int)width0;
        widths[face] = width;
        uint8_t row_seen[TH_N] = {0};
        for (int i = 0; i < width; ++i) {
            int64_t x0 = input[cursor++];
            if (x0 < 0 || x0 >= n || row_seen[x0]) return -1;
            int x = (int)x0;
            row_seen[x] = 1; faces[face][i] = x;
        }
        for (int i = 0; i < width; ++i) {
            int u = faces[face][i], v = faces[face][(i + 1) % width];
            if (!adjacency[u][v]) return -1;
            ++dart_use[u][v];
        }
    }
    if (cursor + (size_t)side_count != length) return -1;
    int apex_positions[TH_N];
    for (int i = 0; i < side_count; ++i) {
        int64_t position = input[cursor++];
        if (position < 0 || position >= widths[outer_id] ||
            (i > 0 && position <= apex_positions[i - 1])) return -1;
        apex_positions[i] = (int)position;
    }
    if (cursor != length) return -1;
    for (int e = 0; e < m; ++e)
        if (dart_use[edge_u[e]][edge_v[e]] != 1 || dart_use[edge_v[e]][edge_u[e]] != 1) return -1;
    if (!th_connected(adjacency, n, -1)) return -1;
    for (int v = 0; v < n; ++v) if (!th_connected(adjacency, n, v)) return -1;

    uint8_t link_adj[TH_N][TH_N][TH_N] = {{{0}}};
    int link_degree[TH_N][TH_N] = {{0}};
    for (int face = 0; face < f; ++face) for (int i = 0; i < widths[face]; ++i) {
        int center = faces[face][i];
        int before = faces[face][(i + widths[face] - 1) % widths[face]];
        int after = faces[face][(i + 1) % widths[face]];
        if (before == after) return -1;
        link_adj[center][before][after] = link_adj[center][after][before] = 1;
        ++link_degree[center][before]; ++link_degree[center][after];
    }
    for (int center = 0; center < n; ++center) {
        int start = -1, incident_count = 0;
        for (int neighbor = 0; neighbor < n; ++neighbor) {
            if (adjacency[center][neighbor]) {
                if (link_degree[center][neighbor] != 2) return -1;
                if (start < 0) start = neighbor;
                ++incident_count;
            } else if (link_degree[center][neighbor] != 0) return -1;
        }
        if (start < 0) return -1;
        uint8_t seen[TH_N] = {0}; int stack[TH_N], top = 0, reached = 0;
        seen[start] = 1; stack[top++] = start;
        while (top) {
            int neighbor = stack[--top]; ++reached;
            for (int other = 0; other < n; ++other)
                if (link_adj[center][neighbor][other] && !seen[other]) {
                    seen[other] = 1; stack[top++] = other;
                }
        }
        if (reached != incident_count) return -1;
    }

    int face_a[TH_M] = {-1}, face_b[TH_M] = {-1}, face_count[TH_M] = {0};
    uint8_t outer_vertices[TH_N] = {0}, outer_edges[TH_N][TH_N] = {{0}};
    for (int i = 0; i < widths[outer_id]; ++i) {
        int u = faces[outer_id][i], v = faces[outer_id][(i + 1) % widths[outer_id]];
        outer_vertices[u] = 1; outer_edges[u][v] = outer_edges[v][u] = 1;
    }
    for (int face = 0; face < f; ++face) for (int i = 0; i < widths[face]; ++i) {
        int u = faces[face][i], v = faces[face][(i + 1) % widths[face]];
        int lo = u < v ? u : v, hi = u < v ? v : u, found = -1;
        for (int e = 0; e < m; ++e) if (edge_u[e] == lo && edge_v[e] == hi) { found = e; break; }
        if (found < 0 || face_count[found] >= 2) return -1;
        if (face_count[found]++ == 0) face_a[found] = face; else face_b[found] = face;
    }
    for (int e = 0; e < m; ++e) if (face_count[e] != 2 || face_a[e] == face_b[e]) return -1;

    uint8_t sides[TH_N][TH_N] = {{0}};
    for (int side = 0; side < side_count; ++side) {
        int at = apex_positions[side], end = apex_positions[(side + 1) % side_count];
        for (;;) {
            sides[side][faces[outer_id][at]] = 1;
            if (at == end) break;
            at = (at + 1) % widths[outer_id];
        }
    }
    int degree[TH_N] = {0};
    for (int u = 0; u < n; ++u) for (int v = 0; v < n; ++v) degree[u] += adjacency[u][v];
    for (int root = 0; root < n; ++root)
        if (!outer_vertices[root] && degree[root] >= 3 &&
            !th_three_outer_paths(adjacency, outer_vertices, n, root)) return 0;

    uint8_t seen_inner[TH_N] = {0};
    for (int seed = 0; seed < n; ++seed) {
        if (outer_vertices[seed] || seen_inner[seed]) continue;
        uint8_t border[TH_N] = {0}; int stack[TH_N], top = 0;
        seen_inner[seed] = 1; stack[top++] = seed;
        while (top) {
            int u = stack[--top];
            for (int v = 0; v < n; ++v) if (adjacency[u][v]) {
                if (outer_vertices[v]) border[v] = 1;
                else if (!seen_inner[v]) { seen_inner[v] = 1; stack[top++] = v; }
            }
        }
        for (int side = 0; side < side_count; ++side) {
            int nonempty = 0, contained = 1;
            for (int v = 0; v < n; ++v) if (border[v]) {
                nonempty = 1; if (!sides[side][v]) contained = 0;
            }
            if (nonempty && contained) return 0;
        }
    }
    for (int e = 0; e < m; ++e) if (!outer_edges[edge_u[e]][edge_v[e]])
        for (int side = 0; side < side_count; ++side)
            if (sides[side][edge_u[e]] && sides[side][edge_v[e]]) return 0;

    uint8_t inner[TH_N][TH_N] = {{0}};
    for (int e = 0; e < m; ++e) if (!outer_edges[edge_u[e]][edge_v[e]])
        inner[edge_u[e]][edge_v[e]] = inner[edge_v[e]][edge_u[e]] = 1;
    return th_condition_three(inner, degree, n) ? 1 : 0;
}
