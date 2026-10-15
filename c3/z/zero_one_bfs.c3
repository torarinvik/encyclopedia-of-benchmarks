module zero_one_bfs;

// 0-1 BFS over a bounded directed graph encoded as weighted edge triples.
fn long zero_one_bfs(long* values, usz length, char* output, usz output_capacity)
    @export("zero_one_bfs")
{
    if (values == null || length < 3 || length > 3075) return -1;
    if (values[0] < 1 || values[0] > 64 || values[2] < 0 || values[2] > 1024) return -1;
    usz vertices = (usz)values[0];
    usz source = (usz)values[1];
    usz edge_count = (usz)values[2];
    if (source >= vertices || length != 3 + 3 * edge_count) return -1;

    ulong[64] zero_edges, one_edges;
    u8[64] distance;
    u8[4097] deque;
    for (usz vertex = 0; vertex < 64; vertex++) {
        zero_edges[vertex] = 0ul;
        one_edges[vertex] = 0ul;
        distance[vertex] = 255;
    }
    for (usz edge = 0; edge < edge_count; edge++) {
        long origin_value = values[3 + 3 * edge];
        long destination_value = values[4 + 3 * edge];
        long weight = values[5 + 3 * edge];
        if (origin_value < 0 || destination_value < 0 ||
            (ulong)origin_value >= (ulong)vertices || (ulong)destination_value >= (ulong)vertices ||
            (weight != 0 && weight != 1)) return -1;
        usz origin = (usz)origin_value;
        usz destination = (usz)destination_value;
        ulong mask = 1ul << (ulong)destination;
        if (weight == 0) zero_edges[origin] = zero_edges[origin] | mask;
        else one_edges[origin] = one_edges[origin] | mask;
    }
    if (output_capacity < vertices || output == null) return -2;

    usz head = 0, tail = 1, queued = 1;
    deque[0] = (u8)source;
    distance[source] = 0;
    while (queued != 0) {
        usz origin = (usz)deque[head];
        head = (head + 1) % 4097;
        queued--;
        u8 base = distance[origin];
        for (usz destination = 0; destination < vertices; destination++) {
            ulong mask = 1ul << (ulong)destination;
            if ((zero_edges[origin] & mask) != 0ul && base < distance[destination]) {
                distance[destination] = base;
                if (head == 0) head = 4096;
                else head--;
                deque[head] = (u8)destination;
                queued++;
            }
            u8 candidate = base + 1;
            if ((one_edges[origin] & mask) != 0ul && candidate < distance[destination]) {
                distance[destination] = candidate;
                deque[tail] = (u8)destination;
                tail = (tail + 1) % 4097;
                queued++;
            }
        }
    }

    for (usz vertex = 0; vertex < vertices; vertex++) output[vertex] = (char)distance[vertex];
    return (long)vertices;
}
