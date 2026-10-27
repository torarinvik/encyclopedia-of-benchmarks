#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 8, MAX_ARCS = 12, MAX_TRIPS = 4, MAX_INPUT = 138, MAX_OUTPUT_BYTES = 88 };
static const int64_t INF = INT64_MAX / 4;

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t timetable_earliest_arrival_dijkstra(const int64_t *input, size_t length,
        uint8_t *output, size_t capacity) {
    if (input == NULL || length < 5 || length > MAX_INPUT) return -1;
    const int64_t n_raw = input[0], arc_count_raw = input[1], source_raw = input[2];
    const int64_t target_raw = input[3], start_time = input[4];
    if (n_raw < 2 || n_raw > MAX_N || arc_count_raw < 0 || arc_count_raw > MAX_ARCS ||
            source_raw < 0 || source_raw >= n_raw || target_raw < 0 || target_raw >= n_raw ||
            start_time < 0 || start_time > 1000) return -1;
    const int n = (int)n_raw, arc_count = (int)arc_count_raw;
    const int source = (int)source_raw, target = (int)target_raw;
    int arc_u[MAX_ARCS], arc_v[MAX_ARCS], trip_count[MAX_ARCS];
    int64_t departure[MAX_ARCS][MAX_TRIPS] = {{0}}, arrival[MAX_ARCS][MAX_TRIPS] = {{0}};
    size_t cursor = 5;
    for (int edge = 0; edge < arc_count; ++edge) {
        if (cursor + 3 > length) return -1;
        const int64_t u_raw = input[cursor++], v_raw = input[cursor++], count_raw = input[cursor++];
        if (u_raw < 0 || u_raw >= n || v_raw < 0 || v_raw >= n || u_raw == v_raw ||
                count_raw < 1 || count_raw > MAX_TRIPS || cursor + 2u * (size_t)count_raw > length) return -1;
        const int u = (int)u_raw, v = (int)v_raw, count = (int)count_raw;
        for (int prior = 0; prior < edge; ++prior)
            if (arc_u[prior] == u && arc_v[prior] == v) return -1;
        arc_u[edge] = u; arc_v[edge] = v; trip_count[edge] = count;
        for (int trip = 0; trip < count; ++trip) {
            const int64_t dep = input[cursor++], arr = input[cursor++];
            if (dep < 0 || dep > 1000 || arr <= dep || arr > 2000 ||
                    (trip > 0 && (dep <= departure[edge][trip - 1] || arr < arrival[edge][trip - 1]))) return -1;
            departure[edge][trip] = dep; arrival[edge][trip] = arr;
        }
    }
    if (cursor != length) return -1;

    int64_t distance[MAX_N];
    int parent[MAX_N];
    uint8_t settled[MAX_N] = {0};
    for (int vertex = 0; vertex < n; ++vertex) { distance[vertex] = INF; parent[vertex] = -1; }
    distance[source] = start_time;
    for (int step = 0; step < n; ++step) {
        int u = -1;
        for (int vertex = 0; vertex < n; ++vertex)
            if (!settled[vertex] && distance[vertex] < INF &&
                    (u < 0 || distance[vertex] < distance[u] ||
                     (distance[vertex] == distance[u] && vertex < u))) u = vertex;
        if (u < 0) break;
        settled[u] = 1;
        for (int edge = 0; edge < arc_count; ++edge) {
            if (arc_u[edge] != u || settled[arc_v[edge]]) continue;
            int trip = 0;
            while (trip < trip_count[edge] && departure[edge][trip] < distance[u]) ++trip;
            if (trip == trip_count[edge]) continue;
            const int v = arc_v[edge];
            const int64_t candidate = arrival[edge][trip];
            if (candidate < distance[v] || (candidate == distance[v] && (parent[v] < 0 || u < parent[v]))) {
                distance[v] = candidate;
                parent[v] = u;
            }
        }
    }

    int reverse_path[MAX_N], path_length = 0;
    if (distance[target] < INF) {
        int current = target;
        reverse_path[path_length++] = current;
        while (current != source && path_length < n) {
            current = parent[current];
            if (current < 0) { path_length = 0; break; }
            reverse_path[path_length++] = current;
        }
        if (path_length == 0 || reverse_path[path_length - 1] != source) path_length = 0;
    }
    const int reachable = path_length > 0;
    const size_t output_words = reachable ? (size_t)(3 + path_length) : 3u;
    const size_t output_bytes = 8u * output_words;
    if (output == NULL || capacity < output_bytes) return -2;
    uint8_t staged[MAX_OUTPUT_BYTES] = {0};
    store_i64_le(staged, 0, reachable ? 1 : 0);
    store_i64_le(staged, 8, reachable ? distance[target] : -1);
    store_i64_le(staged, 16, reachable ? path_length : 0);
    if (reachable) {
        for (int i = 0; i < path_length; ++i)
            store_i64_le(staged, 24u + 8u * (size_t)i, reverse_path[path_length - 1 - i]);
    }
    for (size_t byte = 0; byte < output_bytes; ++byte) output[byte] = staged[byte];
    return (int64_t)output_bytes;
}
