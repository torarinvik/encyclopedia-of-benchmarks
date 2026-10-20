// Based on AtCoder Library mcf_graph::flow (CC0 1.0); see benchmarks/m/min_cost_max_flow/LICENSE.txt.
#include <cstddef>
#include <cstdint>
#include <limits>

#define MCMF_MAX_N 8
#define MCMF_MAX_M 16
#define MCMF_MAX_INPUT (5 + 4 * MCMF_MAX_M)
#define MCMF_OUTPUT_BYTES 16
#define MCMF_INF ((std::int64_t(1)) << 60)

typedef struct { int from, to, rev; std::int64_t cap, cost; } mcmf_edge;

extern "C" std::int64_t min_cost_max_flow(const std::int64_t *input, std::size_t length,
                          std::uint8_t *output, std::size_t output_capacity) {
    if (input == NULL || length < 5 || length > MCMF_MAX_INPUT) return -1;
    std::int64_t n64 = input[0], m64 = input[1], source64 = input[2], sink64 = input[3], limit = input[4];
    if (n64 < 2 || n64 > MCMF_MAX_N || m64 < 0 || m64 > MCMF_MAX_M ||
        length != 5 + 4 * (std::size_t)m64) return -1;
    int n = (int)n64, m = (int)m64;
    if (source64 < 0 || source64 >= n || sink64 < 0 || sink64 >= n || source64 == sink64 ||
        limit < 0 || limit > 16) return -1;
    int source = (int)source64, sink = (int)sink64;
    mcmf_edge edges[2 * MCMF_MAX_M];
    for (int i = 0; i < m; ++i) {
        std::int64_t u = input[5 + 4 * i], v = input[6 + 4 * i];
        std::int64_t cap = input[7 + 4 * i], cost = input[8 + 4 * i];
        if (u < 0 || u >= n || v < 0 || v >= n || cap < 0 || cap > 5 || cost < 0 || cost > 20) return -1;
        int e = 2 * i;
        edges[e] = mcmf_edge{(int)u, (int)v, e + 1, cap, cost};
        edges[e + 1] = mcmf_edge{(int)v, (int)u, e, 0, -cost};
    }
    if (output == NULL || output_capacity < MCMF_OUTPUT_BYTES) return -2;

    std::int64_t potential[MCMF_MAX_N] = {0};
    std::int64_t total_flow = 0, total_cost = 0;
    while (total_flow < limit) {
        std::int64_t dist[MCMF_MAX_N];
        int parent[MCMF_MAX_N], used[MCMF_MAX_N] = {0};
        for (int i = 0; i < n; ++i) { dist[i] = MCMF_INF; parent[i] = -1; }
        dist[source] = 0;
        for (int step = 0; step < n; ++step) {
            int u = -1;
            for (int i = 0; i < n; ++i)
                if (!used[i] && dist[i] != MCMF_INF && (u < 0 || dist[i] < dist[u])) u = i;
            if (u < 0) break;
            used[u] = 1;
            for (int e = 0; e < 2 * m; ++e) if (edges[e].from == u && edges[e].cap > 0) {
                int v = edges[e].to;
                std::int64_t reduced = edges[e].cost + potential[u] - potential[v];
                std::int64_t candidate = dist[u] + reduced;
                if (!used[v] && candidate < dist[v]) { dist[v] = candidate; parent[v] = e; }
            }
        }
        if (dist[sink] == MCMF_INF) break;
        for (int i = 0; i < n; ++i) if (dist[i] != MCMF_INF) potential[i] += dist[i];
        std::int64_t amount = limit - total_flow;
        for (int v = sink; v != source; v = edges[parent[v]].from) {
            if (parent[v] < 0) return -1;
            if (amount > edges[parent[v]].cap) amount = edges[parent[v]].cap;
        }
        for (int v = sink; v != source; v = edges[parent[v]].from) {
            int e = parent[v]; edges[e].cap -= amount; edges[edges[e].rev].cap += amount;
        }
        total_flow += amount;
        total_cost += amount * (potential[sink] - potential[source]);
    }
    std::uint64_t result[2] = {(std::uint64_t)total_flow, (std::uint64_t)total_cost};
    for (std::size_t word = 0; word < 2; ++word)
        for (std::size_t byte = 0; byte < 8; ++byte) output[8 * word + byte] = (std::uint8_t)(result[word] >> (8 * byte));
    return MCMF_OUTPUT_BYTES;
}
