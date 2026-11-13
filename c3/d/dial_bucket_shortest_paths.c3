module dial_bucket_shortest_paths;

const long MAX_N = 16;
const long MAX_M = 64;
const long MAX_DISTANCE = 120;
const long BUCKETS = 9;
const long MAX_RECORDS = 65;
const long MAX_OUTPUT = 128;

fn void put_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

long dial_bucket_shortest_paths(long* input, usz length, char* output, usz capacity)
        @export("dial_bucket_shortest_paths") {
    if (input == null || length < 3 || length > 196) return -1;
    long n64 = input[0], m64 = input[1], source64 = input[2];
    if (n64 < 1 || n64 > MAX_N || m64 < 0 || m64 > MAX_M ||
        source64 < 0 || source64 >= n64 || length != 3 + 3 * (usz)m64) return -1;
    usz n = (usz)n64, m = (usz)m64, source = (usz)source64;

    usz[MAX_M] edge_to, edge_next, edge_head;
    long[MAX_M] edge_weight;
    for (usz vertex = 0; vertex < n; vertex += 1) edge_head[vertex] = MAX_M;
    for (usz edge = 0; edge < m; edge += 1) {
        long u = input[3 + 3 * edge], v = input[4 + 3 * edge], w = input[5 + 3 * edge];
        if (u < 0 || u >= n64 || v < 0 || v >= n64 || w < 0 || w > 8) return -1;
        edge_to[edge] = (usz)v;
        edge_weight[edge] = w;
        edge_next[edge] = edge_head[(usz)u];
        edge_head[(usz)u] = edge;
    }
    usz needed = 8 * n;
    if (output == null || capacity < needed) return -2;

    long[MAX_N] distance;
    bool[MAX_N] settled;
    for (usz vertex = 0; vertex < n; vertex += 1) {
        distance[vertex] = MAX_DISTANCE + 1;
        settled[vertex] = false;
    }
    distance[source] = 0;
    usz[BUCKETS] bucket_head, bucket_tail;
    for (usz bucket = 0; bucket < BUCKETS; bucket += 1)
        bucket_head[bucket] = bucket_tail[bucket] = MAX_RECORDS;
    usz[MAX_RECORDS] record_vertex, record_next;
    long[MAX_RECORDS] record_distance;
    record_vertex[0] = source;
    record_distance[0] = 0;
    record_next[0] = MAX_RECORDS;
    bucket_head[0] = bucket_tail[0] = 0;
    usz used = 1;

    for (usz current = 0; current <= MAX_DISTANCE; current += 1) {
        usz bucket = current % BUCKETS;
        while (bucket_head[bucket] != MAX_RECORDS) {
            usz record = bucket_head[bucket];
            bucket_head[bucket] = record_next[record];
            if (bucket_head[bucket] == MAX_RECORDS) bucket_tail[bucket] = MAX_RECORDS;
            usz u = record_vertex[record];
            if (record_distance[record] != (long)current || settled[u] ||
                distance[u] != (long)current) continue;
            settled[u] = true;
            usz edge = edge_head[u];
            while (edge != MAX_M) {
                usz v = edge_to[edge];
                long candidate = (long)current + edge_weight[edge];
                if (!settled[v] && candidate < distance[v]) {
                    if (used >= MAX_RECORDS) return -1;
                    distance[v] = candidate;
                    usz destination = (usz)candidate % BUCKETS;
                    record_vertex[used] = v;
                    record_distance[used] = candidate;
                    record_next[used] = MAX_RECORDS;
                    if (bucket_tail[destination] == MAX_RECORDS)
                        bucket_head[destination] = used;
                    else
                        record_next[bucket_tail[destination]] = used;
                    bucket_tail[destination] = used;
                    used += 1;
                }
                edge = edge_next[edge];
            }
        }
    }
    char[MAX_OUTPUT] staged;
    for (usz vertex = 0; vertex < n; vertex += 1)
        put_i64_le(&staged[0], 8 * vertex, if distance[vertex] > MAX_DISTANCE { -1 } else { distance[vertex] });
    for (usz byte = 0; byte < needed; byte += 1) output[byte] = staged[byte];
    return (long)needed;
}

