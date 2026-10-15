/* 0-1 BFS over a bounded directed graph encoded as weighted edge triples. */
#include <stddef.h>
#include <stdint.h>

#define ZERO_ONE_MAX_VERTICES 64
#define ZERO_ONE_MAX_EDGES 1024
#define ZERO_ONE_DEQUE_CAPACITY 4097

int64_t zero_one_bfs(const int64_t *values, size_t length,
                     uint8_t *output, size_t output_capacity)
{
    if (values == NULL || length < 3 || length > 3 + 3 * ZERO_ONE_MAX_EDGES) return -1;
    if (values[0] < 1 || values[0] > ZERO_ONE_MAX_VERTICES || values[2] < 0 ||
        values[2] > ZERO_ONE_MAX_EDGES) return -1;
    const size_t vertices = (size_t)values[0];
    const size_t source = (size_t)values[1];
    const size_t edge_count = (size_t)values[2];
    if (source >= vertices || length != 3 + 3 * edge_count) return -1;

    uint64_t zero_edges[ZERO_ONE_MAX_VERTICES] = {0};
    uint64_t one_edges[ZERO_ONE_MAX_VERTICES] = {0};
    uint8_t distance[ZERO_ONE_MAX_VERTICES];
    uint8_t deque[ZERO_ONE_DEQUE_CAPACITY];
    for (size_t vertex = 0; vertex < vertices; ++vertex) distance[vertex] = UINT8_MAX;
    for (size_t edge = 0; edge < edge_count; ++edge) {
        const int64_t origin_value = values[3 + 3 * edge];
        const int64_t destination_value = values[4 + 3 * edge];
        const int64_t weight = values[5 + 3 * edge];
        if (origin_value < 0 || destination_value < 0 ||
            (uint64_t)origin_value >= vertices || (uint64_t)destination_value >= vertices ||
            (weight != 0 && weight != 1)) return -1;
        const size_t origin = (size_t)origin_value;
        const size_t destination = (size_t)destination_value;
        const uint64_t mask = UINT64_C(1) << destination;
        if (weight == 0) zero_edges[origin] |= mask;
        else one_edges[origin] |= mask;
    }
    if (output_capacity < vertices || output == NULL) return -2;

    size_t head = 0, tail = 1, queued = 1;
    deque[0] = (uint8_t)source;
    distance[source] = 0;
    while (queued != 0) {
        const size_t origin = deque[head];
        head = (head + 1) % ZERO_ONE_DEQUE_CAPACITY;
        --queued;
        const uint8_t base = distance[origin];
        for (size_t destination = 0; destination < vertices; ++destination) {
            const uint64_t mask = UINT64_C(1) << destination;
            if ((zero_edges[origin] & mask) != 0 && base < distance[destination]) {
                distance[destination] = base;
                head = head == 0 ? ZERO_ONE_DEQUE_CAPACITY - 1 : head - 1;
                deque[head] = (uint8_t)destination;
                ++queued;
            }
            const uint8_t candidate = (uint8_t)(base + 1);
            if ((one_edges[origin] & mask) != 0 && candidate < distance[destination]) {
                distance[destination] = candidate;
                deque[tail] = (uint8_t)destination;
                tail = (tail + 1) % ZERO_ONE_DEQUE_CAPACITY;
                ++queued;
            }
        }
    }

    for (size_t vertex = 0; vertex < vertices; ++vertex) output[vertex] = distance[vertex];
    return (int64_t)vertices;
}
