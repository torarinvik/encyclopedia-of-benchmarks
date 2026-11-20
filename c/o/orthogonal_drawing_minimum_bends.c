#include <stddef.h>
#include <stdint.h>

#define BEND_MAX_N 8
#define BEND_MAX_M 16
#define BEND_MAX_F 10
#define BEND_MAX_INPUT 79
#define BEND_MAX_NODES (BEND_MAX_N + BEND_MAX_F + 2)
#define BEND_MAX_RESIDUAL 200
#define BEND_INF (INT64_C(1) << 60)

typedef struct { int from, to, reverse; int64_t capacity, cost; } bend_edge;

static int connected_without(const uint8_t adjacency[BEND_MAX_N][BEND_MAX_N], int n, int removed) {
    int start = removed == 0 ? 1 : 0;
    uint8_t seen[BEND_MAX_N] = {0};
    int stack[BEND_MAX_N], top = 0, count = 0;
    seen[start] = 1; stack[top++] = start;
    while (top) {
        int u = stack[--top]; count++;
        for (int v = 0; v < n; ++v)
            if (v != removed && adjacency[u][v] && !seen[v]) { seen[v] = 1; stack[top++] = v; }
    }
    return count == n - (removed >= 0);
}

static int add_arc(bend_edge edges[BEND_MAX_RESIDUAL], int *count, int u, int v,
                   int64_t capacity, int64_t cost) {
    if (*count + 2 > BEND_MAX_RESIDUAL) return 0;
    int e = *count;
    edges[e] = (bend_edge){u, v, e + 1, capacity, cost};
    edges[e + 1] = (bend_edge){v, u, e, 0, -cost};
    *count += 2;
    return 1;
}

int64_t orthogonal_drawing_minimum_bends(const int64_t *input, size_t length,
                                         uint8_t *output, size_t output_capacity) {
    if (input == NULL || length < 4 || length > BEND_MAX_INPUT) return -1;
    int64_t n64 = input[0], m64 = input[1], f64 = input[2], outer64 = input[3];
    if (n64 < 3 || n64 > BEND_MAX_N || m64 < n64 || m64 > BEND_MAX_M ||
        f64 < 2 || f64 > BEND_MAX_F || f64 != m64 - n64 + 2 || outer64 < 0 || outer64 >= f64) return -1;
    int n = (int)n64, m = (int)m64, f = (int)f64, outer = (int)outer64;
    uint8_t adjacency[BEND_MAX_N][BEND_MAX_N] = {{0}};
    int degree[BEND_MAX_N] = {0}, edge_u[BEND_MAX_M], edge_v[BEND_MAX_M];
    int64_t uses[BEND_MAX_N][BEND_MAX_N] = {{0}};
    size_t cursor = 4;
    for (int e = 0; e < m; ++e) {
        if (cursor + 2 > length) return -1;
        int64_t u64 = input[cursor++], v64 = input[cursor++];
        if (u64 < 0 || u64 >= v64 || v64 >= n) return -1;
        int u = (int)u64, v = (int)v64;
        if (adjacency[u][v] || (e && (u < edge_u[e - 1] ||
            (u == edge_u[e - 1] && v <= edge_v[e - 1])))) return -1;
        adjacency[u][v] = adjacency[v][u] = 1;
        degree[u]++; degree[v]++;
        edge_u[e] = u; edge_v[e] = v;
    }
    for (int v = 0; v < n; ++v) if (degree[v] < 2 || degree[v] > 4) return -1;
    int face_vertices[BEND_MAX_F][BEND_MAX_N], face_length[BEND_MAX_F];
    uint8_t link_adjacency[BEND_MAX_N][BEND_MAX_N][BEND_MAX_N] = {{{0}}};
    int link_degree[BEND_MAX_N][BEND_MAX_N] = {{0}};
    for (int face = 0; face < f; ++face) {
        if (cursor >= length) return -1;
        int64_t width64 = input[cursor++];
        if (width64 < 3 || width64 > n || cursor + (size_t)width64 > length) return -1;
        int width = (int)width64;
        face_length[face] = width;
        uint8_t row_seen[BEND_MAX_N] = {0};
        for (int i = 0; i < width; ++i) {
            int64_t vertex64 = input[cursor++];
            if (vertex64 < 0 || vertex64 >= n || row_seen[vertex64]) return -1;
            int vertex = (int)vertex64;
            row_seen[vertex] = 1;
            face_vertices[face][i] = vertex;
        }
        for (int i = 0; i < width; ++i) {
            int u = face_vertices[face][i], v = face_vertices[face][(i + 1) % width];
            if (!adjacency[u][v]) return -1;
            uses[u][v]++;
        }
        for (int i = 0; i < width; ++i) {
            int center = face_vertices[face][i];
            int before = face_vertices[face][(i + width - 1) % width];
            int after = face_vertices[face][(i + 1) % width];
            if (before == after) return -1;
            link_adjacency[center][before][after] = 1;
            link_adjacency[center][after][before] = 1;
            link_degree[center][before]++;
            link_degree[center][after]++;
        }
    }
    if (cursor != length || n - m + f != 2) return -1;
    if (!connected_without(adjacency, n, -1)) return -1;
    for (int removed = 0; removed < n; ++removed)
        if (!connected_without(adjacency, n, removed)) return -1;
    for (int e = 0; e < m; ++e) {
        int u = edge_u[e], v = edge_v[e];
        if (uses[u][v] != 1 || uses[v][u] != 1) return -1;
    }
    for (int center = 0; center < n; ++center) {
        int start = -1, incident_count = 0;
        for (int neighbor = 0; neighbor < n; ++neighbor) {
            if (adjacency[center][neighbor]) {
                if (link_degree[center][neighbor] != 2) return -1;
                if (start < 0) start = neighbor;
                incident_count++;
            } else if (link_degree[center][neighbor] != 0) return -1;
        }
        uint8_t seen[BEND_MAX_N] = {0};
        int stack[BEND_MAX_N], top = 0, reached = 0;
        seen[start] = 1; stack[top++] = start;
        while (top) {
            int neighbor = stack[--top]; reached++;
            for (int other = 0; other < n; ++other)
                if (link_adjacency[center][neighbor][other] && !seen[other]) {
                    seen[other] = 1; stack[top++] = other;
                }
        }
        if (reached != incident_count) return -1;
    }
    int face_a[BEND_MAX_M], face_b[BEND_MAX_M], face_use[BEND_MAX_M] = {0};
    for (int face = 0; face < f; ++face) for (int i = 0; i < face_length[face]; ++i) {
        int u = face_vertices[face][i], v = face_vertices[face][(i + 1) % face_length[face]];
        int lo = u < v ? u : v, hi = u < v ? v : u, found = -1;
        for (int e = 0; e < m; ++e) if (edge_u[e] == lo && edge_v[e] == hi) { found = e; break; }
        if (found < 0 || face_use[found] >= 2) return -1;
        if (face_use[found]++ == 0) face_a[found] = face;
        else face_b[found] = face;
    }
    for (int e = 0; e < m; ++e) if (face_use[e] != 2 || face_a[e] == face_b[e]) return -1;
    if (output == NULL || output_capacity < 8) return -2;

    int original_nodes = n + f, source = original_nodes, sink = original_nodes + 1;
    int node_count = original_nodes + 2, edge_count = 0;
    bend_edge edges[BEND_MAX_RESIDUAL];
    int64_t balance[BEND_MAX_N + BEND_MAX_F] = {0};
    for (int v = 0; v < n; ++v) balance[v] = 4;
    for (int face = 0; face < f; ++face) {
        int d = face_length[face];
        int64_t demand = 2 * d + (face == outer ? 4 : -4);
        balance[n + face] -= demand;
        for (int i = 0; i < d; ++i) {
            int v = face_vertices[face][i];
            balance[v]--; balance[n + face]++;
            if (!add_arc(edges, &edge_count, v, n + face, 4 * n, 0)) return -1;
        }
    }
    for (int e = 0; e < m; ++e) {
        if (!add_arc(edges, &edge_count, n + face_a[e], n + face_b[e], 4 * n, 1) ||
            !add_arc(edges, &edge_count, n + face_b[e], n + face_a[e], 4 * n, 1)) return -1;
    }
    int64_t required = 0;
    for (int v = 0; v < original_nodes; ++v) {
        if (balance[v] > 0) {
            if (!add_arc(edges, &edge_count, source, v, balance[v], 0)) return -1;
            required += balance[v];
        } else if (balance[v] < 0) {
            if (!add_arc(edges, &edge_count, v, sink, -balance[v], 0)) return -1;
        }
    }
    int64_t potential[BEND_MAX_NODES] = {0}, total_flow = 0, total_cost = 0;
    while (total_flow < required) {
        int64_t dist[BEND_MAX_NODES];
        int parent[BEND_MAX_NODES], used[BEND_MAX_NODES] = {0};
        for (int v = 0; v < node_count; ++v) { dist[v] = BEND_INF; parent[v] = -1; }
        dist[source] = 0;
        for (int step = 0; step < node_count; ++step) {
            int u = -1;
            for (int v = 0; v < node_count; ++v)
                if (!used[v] && dist[v] != BEND_INF && (u < 0 || dist[v] < dist[u])) u = v;
            if (u < 0) break;
            used[u] = 1;
            for (int e = 0; e < edge_count; ++e) if (edges[e].from == u && edges[e].capacity > 0) {
                int v = edges[e].to;
                int64_t candidate = dist[u] + edges[e].cost + potential[u] - potential[v];
                if (!used[v] && candidate < dist[v]) { dist[v] = candidate; parent[v] = e; }
            }
        }
        if (dist[sink] == BEND_INF) return -1;
        for (int v = 0; v < node_count; ++v) if (dist[v] != BEND_INF) potential[v] += dist[v];
        int64_t amount = required - total_flow, path_cost = 0;
        for (int v = sink; v != source; v = edges[parent[v]].from) {
            if (parent[v] < 0) return -1;
            if (amount > edges[parent[v]].capacity) amount = edges[parent[v]].capacity;
            path_cost += edges[parent[v]].cost;
        }
        for (int v = sink; v != source; v = edges[parent[v]].from) {
            int e = parent[v];
            edges[e].capacity -= amount;
            edges[edges[e].reverse].capacity += amount;
        }
        total_flow += amount;
        total_cost += amount * path_cost;
    }
    uint64_t bits = (uint64_t)total_cost;
    for (size_t i = 0; i < 8; ++i) output[i] = (uint8_t)(bits >> (8 * i));
    return 8;
}
