module edge_connectivity_all_pairs_maxflow;

const usz MAX_VERTICES = 10;
const usz MAX_EDGES = 45;
const usz MAX_PARSEABLE = 93;

fn long edge_connectivity_all_pairs_maxflow(long* input, usz length) @export("edge_connectivity_all_pairs_maxflow") {
    if (input == null || length < 2 || length > MAX_PARSEABLE) return -1;
    if (input[0] < 2 || input[0] > (long)MAX_VERTICES || input[1] < 0 || input[1] > (long)MAX_EDGES) return -1;
    usz n = (usz)input[0], m = (usz)input[1];
    if (length != 2 + 2 * m) return -1;

    int[MAX_VERTICES * MAX_VERTICES] adjacency;
    for (usz i = 0; i < MAX_VERTICES * MAX_VERTICES; i++) adjacency[i] = 0;
    for (usz e = 0; e < m; e++) {
        long left = input[2 + 2 * e], right = input[3 + 2 * e];
        if (left < 0 || right < 0 || left >= (long)n || right >= (long)n || left == right) return -1;
        usz u = (usz)left, v = (usz)right;
        if (adjacency[u * MAX_VERTICES + v] != 0) return -1;
        adjacency[u * MAX_VERTICES + v] = 1;
        adjacency[v * MAX_VERTICES + u] = 1;
    }

    long best = (long)n - 1;
    for (usz source = 0; source < n; source++) {
        for (usz sink = source + 1; sink < n; sink++) {
            long residual[MAX_VERTICES * MAX_VERTICES];
            for (usz i = 0; i < MAX_VERTICES * MAX_VERTICES; i++) residual[i] = adjacency[i];
            long flow = 0;
            while (flow < best) {
                long[MAX_VERTICES] parent;
                usz[MAX_VERTICES] queue;
                for (usz v = 0; v < n; v++) parent[v] = -1;
                parent[source] = (long)source;
                usz head = 0, tail = 0;
                queue[tail++] = source;
                while (head < tail && parent[sink] < 0) {
                    usz u = queue[head++];
                    for (usz v = 0; v < n; v++) {
                        if (parent[v] < 0 && residual[u * MAX_VERTICES + v] > 0) {
                            parent[v] = (long)u;
                            queue[tail++] = v;
                            if (v == sink) break;
                        }
                    }
                }
                if (parent[sink] < 0) break;
                long amount = best - flow;
                for (usz v = sink; v != source; v = (usz)parent[v]) {
                    usz u = (usz)parent[v];
                    if (residual[u * MAX_VERTICES + v] < amount) amount = residual[u * MAX_VERTICES + v];
                }
                for (usz v = sink; v != source; v = (usz)parent[v]) {
                    usz u = (usz)parent[v];
                    residual[u * MAX_VERTICES + v] -= amount;
                    residual[v * MAX_VERTICES + u] += amount;
                }
                flow += amount;
            }
            if (flow < best) best = flow;
            if (best == 0) return 0;
        }
    }
    return best;
}
