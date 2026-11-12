module min_cost_max_flow_blocking_paths;

// Clean-room shortest-path tight-edge blocking-flow method; see package RIGHTS.md.
const long INF = 1152921504606846976;
struct Edge { int from; int to; int rev; long cap; long cost; }

fn long send_tight_level_flow(int u, int sink, long limit, Edge* edges,
        int arc_count, long* dist, int* level, int* current) {
    if (u == sink) return limit;
    while (current[u] < arc_count) {
        int e = current[u];
        if (edges[e].from != u || edges[e].cap <= 0) { current[u] = current[u] + 1; continue; }
        int v = edges[e].to;
        if (dist[v] == INF || dist[v] != dist[u] + edges[e].cost || level[v] != level[u] + 1) {
            current[u] = current[u] + 1; continue;
        }
        long amount = limit < edges[e].cap ? limit : edges[e].cap;
        long sent = send_tight_level_flow(v, sink, amount, edges, arc_count, dist, level, current);
        if (sent > 0) {
            edges[e].cap = edges[e].cap - sent;
            edges[edges[e].rev].cap = edges[edges[e].rev].cap + sent;
            if (edges[e].cap == 0) current[u] = current[u] + 1;
            return sent;
        }
        current[u] = current[u] + 1;
    }
    return 0;
}

fn long min_cost_max_flow_blocking_paths(long* input, usz length, uint8* output, usz output_capacity)
    @export("min_cost_max_flow_blocking_paths") {
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
    long total_flow = 0, total_cost = 0;
    while (total_flow < flow_limit) {
        long[8] dist;
        int[8] queue;
        bool[8] in_queue;
        for (int i = 0; i < n; i++) { dist[i] = INF; in_queue[i] = false; }
        dist[source] = 0;
        int head = 0, tail = 0, queued = 0;
        queue[tail] = source; tail = (tail + 1) % n; queued++; in_queue[source] = true;
        while (queued > 0) {
            int u = queue[head]; head = (head + 1) % n; queued--; in_queue[u] = false;
            for (int e = 0; e < 2 * m; e++) if (edges[e].from == u && edges[e].cap > 0) {
                int v = edges[e].to;
                long candidate = dist[u] + edges[e].cost;
                if (candidate < dist[v]) {
                    dist[v] = candidate;
                    if (!in_queue[v]) { queue[tail] = v; tail = (tail + 1) % n; queued++; in_queue[v] = true; }
                }
            }
        }
        if (dist[sink] == INF) break;
        while (total_flow < flow_limit) {
            int[8] level, breadth, current;
            for (int i = 0; i < n; i++) { level[i] = -1; current[i] = 0; }
            int first = 0, last = 0;
            level[source] = 0; breadth[last] = source; last++;
            while (first < last) {
                int u = breadth[first]; first++;
                for (int e = 0; e < 2 * m; e++) if (edges[e].from == u && edges[e].cap > 0) {
                    int v = edges[e].to;
                    if (dist[v] == dist[u] + edges[e].cost && level[v] < 0) {
                        level[v] = level[u] + 1; breadth[last] = v; last++;
                    }
                }
            }
            if (level[sink] < 0) break;
            long amount = send_tight_level_flow(source, sink, flow_limit - total_flow,
                &edges[0], 2 * m, &dist[0], &level[0], &current[0]);
            if (amount == 0) break;
            total_flow += amount;
            total_cost += amount * dist[sink];
        }
    }
    ulong flow_bits = (ulong)total_flow, cost_bits = (ulong)total_cost;
    for (usz i = 0; i < 8; i++) { output[i] = (uint8)(flow_bits >> (8 * i)); output[8 + i] = (uint8)(cost_bits >> (8 * i)); }
    return 16;
}
