// Clean-room shortest-path tight-edge blocking-flow method; see package RIGHTS.md.
#include <cstddef>
#include <cstdint>

#define MCMF_MAX_N 8
#define MCMF_MAX_M 16
#define MCMF_MAX_INPUT (5 + 4 * MCMF_MAX_M)
#define MCMF_OUTPUT_BYTES 16
#define MCMF_INF ((std::int64_t(1)) << 60)

struct McmfEdge { int from, to, rev; std::int64_t cap, cost; };

static std::int64_t send_tight_level_flow(int u, int sink, std::int64_t limit,
        McmfEdge *edges, int arc_count, const std::int64_t *dist,
        const int *level, int *current) {
    if (u == sink) return limit;
    for (int &cursor = current[u]; cursor < arc_count;) {
        int e = cursor;
        if (edges[e].from != u || edges[e].cap <= 0) { ++cursor; continue; }
        int v = edges[e].to;
        if (dist[v] == MCMF_INF || dist[v] != dist[u] + edges[e].cost ||
                level[v] != level[u] + 1) { ++cursor; continue; }
        std::int64_t amount = limit < edges[e].cap ? limit : edges[e].cap;
        std::int64_t sent = send_tight_level_flow(v, sink, amount, edges, arc_count, dist, level, current);
        if (sent > 0) {
            edges[e].cap -= sent;
            edges[edges[e].rev].cap += sent;
            if (edges[e].cap == 0) ++cursor;
            return sent;
        }
        ++cursor;
    }
    return 0;
}

extern "C" std::int64_t min_cost_max_flow_blocking_paths(const std::int64_t *input, std::size_t length,
                          std::uint8_t *output, std::size_t output_capacity) {
    if (input == nullptr || length < 5 || length > MCMF_MAX_INPUT) return -1;
    std::int64_t n64 = input[0], m64 = input[1], source64 = input[2], sink64 = input[3], limit = input[4];
    if (n64 < 2 || n64 > MCMF_MAX_N || m64 < 0 || m64 > MCMF_MAX_M ||
        length != 5 + 4 * (std::size_t)m64) return -1;
    int n = (int)n64, m = (int)m64;
    if (source64 < 0 || source64 >= n || sink64 < 0 || sink64 >= n || source64 == sink64 ||
        limit < 0 || limit > 16) return -1;
    int source = (int)source64, sink = (int)sink64;
    McmfEdge edges[2 * MCMF_MAX_M];
    for (int i = 0; i < m; ++i) {
        std::int64_t u = input[5 + 4 * i], v = input[6 + 4 * i];
        std::int64_t cap = input[7 + 4 * i], cost = input[8 + 4 * i];
        if (u < 0 || u >= n || v < 0 || v >= n || cap < 0 || cap > 5 || cost < 0 || cost > 20) return -1;
        int e = 2 * i;
        edges[e] = McmfEdge{(int)u, (int)v, e + 1, cap, cost};
        edges[e + 1] = McmfEdge{(int)v, (int)u, e, 0, -cost};
    }
    if (output == nullptr || output_capacity < MCMF_OUTPUT_BYTES) return -2;

    std::int64_t total_flow = 0, total_cost = 0;
    while (total_flow < limit) {
        std::int64_t dist[MCMF_MAX_N];
        int queue[MCMF_MAX_N], in_queue[MCMF_MAX_N] = {0};
        for (int i = 0; i < n; ++i) dist[i] = MCMF_INF;
        dist[source] = 0;
        int head = 0, tail = 0, queued = 0;
        queue[tail] = source; tail = (tail + 1) % n; ++queued; in_queue[source] = 1;
        while (queued > 0) {
            int u = queue[head]; head = (head + 1) % n; --queued; in_queue[u] = 0;
            for (int e = 0; e < 2 * m; ++e) if (edges[e].from == u && edges[e].cap > 0) {
                int v = edges[e].to;
                std::int64_t candidate = dist[u] + edges[e].cost;
                if (candidate < dist[v]) {
                    dist[v] = candidate;
                    if (!in_queue[v]) {
                        queue[tail] = v; tail = (tail + 1) % n; ++queued; in_queue[v] = 1;
                    }
                }
            }
        }
        if (dist[sink] == MCMF_INF) break;

        while (total_flow < limit) {
            int level[MCMF_MAX_N], breadth[MCMF_MAX_N], current[MCMF_MAX_N];
            for (int i = 0; i < n; ++i) { level[i] = -1; current[i] = 0; }
            int first = 0, last = 0;
            level[source] = 0; breadth[last++] = source;
            while (first < last) {
                int u = breadth[first++];
                for (int e = 0; e < 2 * m; ++e) if (edges[e].from == u && edges[e].cap > 0) {
                    int v = edges[e].to;
                    if (dist[v] == dist[u] + edges[e].cost && level[v] < 0) {
                        level[v] = level[u] + 1; breadth[last++] = v;
                    }
                }
            }
            if (level[sink] < 0) break;
            std::int64_t amount = send_tight_level_flow(source, sink, limit - total_flow,
                edges, 2 * m, dist, level, current);
            if (amount == 0) break;
            total_flow += amount;
            total_cost += amount * dist[sink];
        }
    }
    std::uint64_t result[2] = {(std::uint64_t)total_flow, (std::uint64_t)total_cost};
    for (std::size_t word = 0; word < 2; ++word)
        for (std::size_t byte = 0; byte < 8; ++byte) output[8 * word + byte] = (std::uint8_t)(result[word] >> (8 * byte));
    return MCMF_OUTPUT_BYTES;
}
