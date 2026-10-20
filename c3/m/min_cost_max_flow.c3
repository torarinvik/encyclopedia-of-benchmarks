module min_cost_max_flow;

// Based on AtCoder Library mcf_graph::flow (CC0 1.0); see benchmarks/m/min_cost_max_flow/LICENSE.txt.

const usz MAX_N = 8;
const usz MAX_M = 16;
const long INF = 1152921504606846976;
struct Edge { int from; int to; int rev; long cap; long cost; }

fn long min_cost_max_flow(long* input, usz length, uint8* output, usz output_capacity)
    @export("min_cost_max_flow") {
    if (input == null || length < 5 || length > 69) return -1;
    long n_value = input[0], m_value = input[1];
    long source_value = input[2], sink_value = input[3], flow_limit = input[4];
    if (n_value < 2 || n_value > 8 || m_value < 0 || m_value > 16 ||
        length != 5 + 4 * (usz)m_value) return -1;
    int n = (int)n_value, m = (int)m_value;
    if (source_value < 0 || source_value >= n || sink_value < 0 || sink_value >= n ||
        source_value == sink_value || flow_limit < 0 || flow_limit > 16) return -1;
    int source = (int)source_value, sink = (int)sink_value;
    Edge[32] edges;
    for (int i = 0; i < m; i++) {
        long u = input[5 + 4 * i], v = input[6 + 4 * i];
        long cap = input[7 + 4 * i], cost = input[8 + 4 * i];
        if (u < 0 || u >= n || v < 0 || v >= n || cap < 0 || cap > 5 || cost < 0 || cost > 20) return -1;
        int e = 2 * i;
        edges[e] = Edge{(int)u, (int)v, e + 1, cap, cost};
        edges[e + 1] = Edge{(int)v, (int)u, e, 0, -cost};
    }
    if (output == null || output_capacity < 16) return -2;
    long[8] potential;
    for (int i = 0; i < n; i++) potential[i] = 0;
    long total_flow = 0, total_cost = 0;
    while (total_flow < flow_limit) {
        long[8] dist;
        int[8] parent;
        bool[8] used;
        for (int i = 0; i < n; i++) { dist[i] = INF; parent[i] = -1; used[i] = false; }
        dist[source] = 0;
        for (int step = 0; step < n; step++) {
            int u = -1;
            for (int i = 0; i < n; i++) if (!used[i] && dist[i] != INF && (u < 0 || dist[i] < dist[u])) u = i;
            if (u < 0) break;
            used[u] = true;
            for (int e = 0; e < 2 * m; e++) if (edges[e].from == u && edges[e].cap > 0) {
                int v = edges[e].to;
                long candidate = dist[u] + edges[e].cost + potential[u] - potential[v];
                if (!used[v] && candidate < dist[v]) { dist[v] = candidate; parent[v] = e; }
            }
        }
        if (dist[sink] == INF) break;
        for (int i = 0; i < n; i++) if (dist[i] != INF) potential[i] += dist[i];
        long amount = flow_limit - total_flow;
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
    ulong flow_bits = (ulong)total_flow, cost_bits = (ulong)total_cost;
    for (usz i = 0; i < 8; i++) { output[i] = (uint8)(flow_bits >> (8 * i)); output[8 + i] = (uint8)(cost_bits >> (8 * i)); }
    return 16;
}
