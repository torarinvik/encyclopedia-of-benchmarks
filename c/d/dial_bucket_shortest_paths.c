#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 16, MAX_M = 64, MAX_INPUT = 196, MAX_OUTPUT = 128,
       MAX_DISTANCE = 120, BUCKETS = 9, MAX_RECORDS = MAX_M + 1 };

static void put_i64_le(uint8_t *dst, size_t offset, int64_t value)
{
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        dst[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t dial_bucket_shortest_paths(const int64_t *input, size_t length,
                                   uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 3 || length > MAX_INPUT) return -1;
    const int64_t n64 = input[0], m64 = input[1], source64 = input[2];
    if (n64 < 1 || n64 > MAX_N || m64 < 0 || m64 > MAX_M ||
        source64 < 0 || source64 >= n64 || length != 3 + 3 * (size_t)m64) return -1;
    const size_t n = (size_t)n64, m = (size_t)m64, source = (size_t)source64;

    size_t edge_to[MAX_M], edge_next[MAX_M];
    int64_t edge_weight[MAX_M];
    size_t edge_head[MAX_N];
    for (size_t vertex = 0; vertex < n; ++vertex) edge_head[vertex] = MAX_M;
    for (size_t edge = 0; edge < m; ++edge) {
        const int64_t u = input[3 + 3 * edge], v = input[4 + 3 * edge], w = input[5 + 3 * edge];
        if (u < 0 || u >= n64 || v < 0 || v >= n64 || w < 0 || w > 8) return -1;
        const size_t from = (size_t)u;
        edge_to[edge] = (size_t)v;
        edge_weight[edge] = w;
        edge_next[edge] = edge_head[from];
        edge_head[from] = edge;
    }
    const size_t needed = 8 * n;
    if (output == NULL || capacity < needed) return -2;

    int64_t distance[MAX_N];
    uint8_t settled[MAX_N] = {0};
    for (size_t vertex = 0; vertex < n; ++vertex) distance[vertex] = MAX_DISTANCE + 1;
    distance[source] = 0;

    size_t bucket_head[BUCKETS], bucket_tail[BUCKETS];
    for (size_t bucket = 0; bucket < BUCKETS; ++bucket)
        bucket_head[bucket] = bucket_tail[bucket] = MAX_RECORDS;
    size_t record_vertex[MAX_RECORDS], record_next[MAX_RECORDS], used = 0;
    int64_t record_distance[MAX_RECORDS];
    record_vertex[0] = source;
    record_distance[0] = 0;
    record_next[0] = MAX_RECORDS;
    bucket_head[0] = bucket_tail[0] = 0;
    used = 1;

    for (size_t current = 0; current <= MAX_DISTANCE; ++current) {
        const size_t bucket = current % BUCKETS;
        while (bucket_head[bucket] != MAX_RECORDS) {
            const size_t record = bucket_head[bucket];
            bucket_head[bucket] = record_next[record];
            if (bucket_head[bucket] == MAX_RECORDS) bucket_tail[bucket] = MAX_RECORDS;
            const size_t u = record_vertex[record];
            if (record_distance[record] != (int64_t)current ||
                settled[u] || distance[u] != (int64_t)current) continue;
            settled[u] = 1;
            for (size_t edge = edge_head[u]; edge != MAX_M; edge = edge_next[edge]) {
                const size_t v = edge_to[edge];
                const int64_t candidate = (int64_t)current + edge_weight[edge];
                if (!settled[v] && candidate < distance[v]) {
                    if (used >= MAX_RECORDS) return -1;
                    distance[v] = candidate;
                    const size_t destination = (size_t)candidate % BUCKETS;
                    record_vertex[used] = v;
                    record_distance[used] = candidate;
                    record_next[used] = MAX_RECORDS;
                    if (bucket_tail[destination] == MAX_RECORDS)
                        bucket_head[destination] = used;
                    else
                        record_next[bucket_tail[destination]] = used;
                    bucket_tail[destination] = used++;
                }
            }
        }
    }

    uint8_t staged[MAX_OUTPUT];
    for (size_t vertex = 0; vertex < n; ++vertex)
        put_i64_le(staged, 8 * vertex, distance[vertex] > MAX_DISTANCE ? -1 : distance[vertex]);
    for (size_t byte = 0; byte < needed; ++byte) output[byte] = staged[byte];
    return (int64_t)needed;
}

