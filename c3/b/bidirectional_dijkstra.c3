module bidirectional_dijkstra;

const int MAX_VERTICES = 64;
const int MAX_EDGES = 256;
const long MAX_WEIGHT = 1000000;
const long INF = 1000000000;

fn long bidirectional_dijkstra(long* input, usz length) @export("bidirectional_dijkstra") {
    if (input == null || length < 4) return -1;
    long nv = input[0], mv = input[1], source_v = input[2], target_v = input[3];
    if (nv < 1 || nv > MAX_VERTICES || mv < 0 || mv > MAX_EDGES) return -1;
    if (source_v < 0 || source_v >= nv || target_v < 0 || target_v >= nv) return -1;
    int n = (int)nv, m = (int)mv;
    if (length != 4 + 3 * (usz)m) return -1;
    for (int edge = 0; edge < m; edge++) {
        long from = input[4 + 3 * edge], to = input[5 + 3 * edge], weight = input[6 + 3 * edge];
        if (from < 0 || from >= nv || to < 0 || to >= nv || weight < 0 || weight > MAX_WEIGHT) return -1;
    }
    int source = (int)source_v, target = (int)target_v;
    if (source == target) return 0;

    long[MAX_VERTICES] forward, backward;
    bool[MAX_VERTICES] settled_forward, settled_backward;
    for (int vertex = 0; vertex < n; vertex++) {
        forward[vertex] = INF;
        backward[vertex] = INF;
        settled_forward[vertex] = false;
        settled_backward[vertex] = false;
    }
    forward[source] = 0;
    backward[target] = 0;
    long best = INF;

    for (int step = 0; step < 2 * n; step++) {
        int next_forward = n, next_backward = n;
        long min_forward = INF, min_backward = INF;
        for (int vertex = 0; vertex < n; vertex++) {
            if (!settled_forward[vertex] && forward[vertex] < min_forward) {
                min_forward = forward[vertex];
                next_forward = vertex;
            }
            if (!settled_backward[vertex] && backward[vertex] < min_backward) {
                min_backward = backward[vertex];
                next_backward = vertex;
            }
        }
        if (next_forward == n || next_backward == n) break;
        if (best != INF && min_forward + min_backward >= best) break;

        if (min_forward <= min_backward) {
            int current = next_forward;
            settled_forward[current] = true;
            if (backward[current] != INF && forward[current] + backward[current] < best)
                best = forward[current] + backward[current];
            for (int edge = 0; edge < m; edge++) {
                if ((int)input[4 + 3 * edge] != current) continue;
                int to = (int)input[5 + 3 * edge];
                long candidate = forward[current] + input[6 + 3 * edge];
                if (!settled_forward[to] && candidate < forward[to]) forward[to] = candidate;
                if (backward[to] != INF && candidate + backward[to] < best) best = candidate + backward[to];
            }
        } else {
            int current = next_backward;
            settled_backward[current] = true;
            if (forward[current] != INF && forward[current] + backward[current] < best)
                best = forward[current] + backward[current];
            for (int edge = 0; edge < m; edge++) {
                if ((int)input[5 + 3 * edge] != current) continue;
                int from = (int)input[4 + 3 * edge];
                long candidate = backward[current] + input[6 + 3 * edge];
                if (!settled_backward[from] && candidate < backward[from]) backward[from] = candidate;
                if (forward[from] != INF && forward[from] + input[6 + 3 * edge] + backward[current] < best)
                    best = forward[from] + input[6 + 3 * edge] + backward[current];
            }
        }
    }
    return best == INF ? -1 : best;
}
