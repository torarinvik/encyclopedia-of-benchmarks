/* Clean-room bounded GAPBS delta-stepping profile; see package LICENSE.txt. */
#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 16, MAX_M = 64, MAX_INPUT = 4 + 3 * MAX_M,
       MAX_DISTANCE = 480, MAX_BUCKETS = MAX_DISTANCE + 1, MAX_EVENTS = 8192 };
static const int64_t INF_DISTANCE = INT64_C(1073741823);

static int append_event(int bucket, int vertex, int *heads, int *tails,
                        int *event_vertex, int *event_next, int *used) {
    if (*used >= MAX_EVENTS || bucket < 0 || bucket >= MAX_BUCKETS) return 0;
    const int event = (*used)++;
    event_vertex[event] = vertex;
    event_next[event] = -1;
    if (heads[bucket] < 0) heads[bucket] = event;
    else event_next[tails[bucket]] = event;
    tails[bucket] = event;
    return 1;
}

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & UINT64_C(255));
        bits >>= 8;
    }
}

int64_t gapbs_delta_step_sssp(const int64_t *input, size_t length,
                              uint8_t *output, size_t capacity) {
    if (input == NULL || length < 4 || length > MAX_INPUT) return -1;
    const int64_t n64 = input[0], m64 = input[1], source64 = input[2], delta64 = input[3];
    if (n64 < 1 || n64 > MAX_N || m64 < 0 || m64 > MAX_M ||
        source64 < 0 || source64 >= n64 || delta64 < 1 || delta64 > 16 ||
        length != 4 + 3 * (size_t)m64) return -1;
    const int n = (int)n64, m = (int)m64, delta = (int)delta64;
    int edge_from[MAX_M], edge_to[MAX_M], edge_weight[MAX_M];
    for (int edge = 0; edge < m; ++edge) {
        const int64_t from = input[4 + 3 * (size_t)edge];
        const int64_t to = input[5 + 3 * (size_t)edge];
        const int64_t weight = input[6 + 3 * (size_t)edge];
        if (from < 0 || from >= n64 || to < 0 || to >= n64 || weight < 0 || weight > 32) return -1;
        edge_from[edge] = (int)from;
        edge_to[edge] = (int)to;
        edge_weight[edge] = (int)weight;
    }
    const size_t output_bytes = 8 * (size_t)n;
    if (output == NULL || capacity < output_bytes) return -2;

    int64_t distance[MAX_N];
    for (int vertex = 0; vertex < n; ++vertex) distance[vertex] = INF_DISTANCE;
    distance[(int)source64] = 0;
    int heads[MAX_BUCKETS], tails[MAX_BUCKETS];
    for (int bucket = 0; bucket < MAX_BUCKETS; ++bucket) heads[bucket] = tails[bucket] = -1;
    int event_vertex[MAX_EVENTS], event_next[MAX_EVENTS], used = 0;
    if (!append_event(0, (int)source64, heads, tails, event_vertex, event_next, &used)) return -1;

    for (int bucket = 0; bucket < MAX_BUCKETS; ++bucket) {
        while (heads[bucket] >= 0) {
            const int event = heads[bucket];
            heads[bucket] = event_next[event];
            if (heads[bucket] < 0) tails[bucket] = -1;
            const int u = event_vertex[event];
            if (distance[u] < (int64_t)delta * bucket) continue;
            for (int edge = 0; edge < m; ++edge) {
                if (edge_from[edge] != u) continue;
                const int v = edge_to[edge];
                const int64_t candidate = distance[u] + edge_weight[edge];
                if (candidate < distance[v]) {
                    distance[v] = candidate;
                    const int destination_bucket = (int)(candidate / delta);
                    if (!append_event(destination_bucket, v, heads, tails,
                                     event_vertex, event_next, &used)) return -1;
                }
            }
        }
    }
    for (int vertex = 0; vertex < n; ++vertex) store_i64_le(output, 8 * (size_t)vertex, distance[vertex]);
    return (int64_t)output_bytes;
}
