module gapbs_delta_step_sssp;

const long MAX_N = 16;
const long MAX_M = 64;
const long MAX_BUCKETS = 481;
const long MAX_EVENTS = 8192;
const long INF_DISTANCE = 1073741823;

fn bool append_event(usz bucket, usz vertex, int* heads, int* tails,
        int* event_vertex, int* event_next, usz* used) {
    if (bucket >= 481 || used[0] >= 8192) return false;
    int event = (int)used[0];
    used[0] += 1;
    event_vertex[event] = (int)vertex;
    event_next[event] = -1;
    if (heads[bucket] < 0) heads[bucket] = event;
    else event_next[(usz)tails[bucket]] = event;
    tails[bucket] = event;
    return true;
}

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz b = 0; b < 8; b += 1) {
        output[offset + b] = (char)(bits & 255);
        bits >>= 8;
    }
}

// Clean-room bounded GAPBS delta-stepping profile; see package LICENSE.txt.
long gapbs_delta_step_sssp(long* input, usz length, char* output, usz capacity)
        @export("gapbs_delta_step_sssp") {
    if (input == null || length < 4 || length > 196) return -1;
    long n64 = input[0], m64 = input[1], source64 = input[2], delta = input[3];
    if (n64 < 1 || n64 > MAX_N || m64 < 0 || m64 > MAX_M || source64 < 0 ||
        source64 >= n64 || delta < 1 || delta > 16 || length != 4 + 3 * (usz)m64) return -1;
    usz n = (usz)n64, m = (usz)m64, source = (usz)source64;
    usz[MAX_M] edge_from;
    usz[MAX_M] edge_to;
    long[MAX_M] edge_weight;
    for (usz edge = 0; edge < m; edge += 1) {
        long from = input[4 + 3 * edge], to = input[5 + 3 * edge], weight = input[6 + 3 * edge];
        if (from < 0 || from >= n64 || to < 0 || to >= n64 || weight < 0 || weight > 32) return -1;
        edge_from[edge] = (usz)from;
        edge_to[edge] = (usz)to;
        edge_weight[edge] = weight;
    }
    usz output_bytes = 8 * n;
    if (output == null || capacity < output_bytes) return -2;

    long[MAX_N] distance;
    for (usz vertex = 0; vertex < n; vertex += 1) distance[vertex] = INF_DISTANCE;
    distance[source] = 0;
    int[MAX_BUCKETS] heads;
    int[MAX_BUCKETS] tails;
    for (usz bucket = 0; bucket < MAX_BUCKETS; bucket += 1) { heads[bucket] = -1; tails[bucket] = -1; }
    int[MAX_EVENTS] event_vertex;
    int[MAX_EVENTS] event_next;
    usz used = 0;
    if (!append_event(0, source, &heads[0], &tails[0], &event_vertex[0], &event_next[0], &used)) return -1;

    for (usz bucket = 0; bucket < MAX_BUCKETS; bucket += 1) {
        while (heads[bucket] >= 0) {
            usz event = (usz)heads[bucket];
            heads[bucket] = event_next[event];
            if (heads[bucket] < 0) tails[bucket] = -1;
            usz u = (usz)event_vertex[event];
            if (distance[u] < delta * (long)bucket) continue;
            for (usz edge = 0; edge < m; edge += 1) {
                if (edge_from[edge] != u) continue;
                usz v = edge_to[edge];
                long candidate = distance[u] + edge_weight[edge];
                if (candidate < distance[v]) {
                    distance[v] = candidate;
                    usz destination = (usz)(candidate / delta);
                    if (!append_event(destination, v, &heads[0], &tails[0], &event_vertex[0], &event_next[0], &used)) return -1;
                }
            }
        }
    }
    for (usz vertex = 0; vertex < n; vertex += 1) store_i64_le(output, 8 * vertex, distance[vertex]);
    return (long)output_bytes;
}
