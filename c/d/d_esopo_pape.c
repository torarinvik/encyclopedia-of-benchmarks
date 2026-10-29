#include <stddef.h>
#include <stdint.h>

#define MAX_VERTICES 16
#define MAX_EDGES 64
#define MAX_INPUT_LENGTH (3 + 3 * MAX_EDGES)

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (byte * 8));
}

int64_t d_esopo_pape(const int64_t *values, size_t length,
                     uint8_t *output, size_t capacity) {
    if (values == NULL || length < 3 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t raw_n = values[0], raw_m = values[1], raw_source = values[2];
    if (raw_n < 1 || raw_n > MAX_VERTICES || raw_m < 0 || raw_m > MAX_EDGES ||
        raw_source < 0 || raw_source >= raw_n || length != 3 + 3 * (size_t)raw_m)
        return -1;

    const size_t n = (size_t)raw_n, m = (size_t)raw_m;
    int head[MAX_VERTICES], to[MAX_EDGES], next[MAX_EDGES];
    int64_t weight[MAX_EDGES];
    for (size_t vertex = 0; vertex < n; ++vertex) head[vertex] = -1;
    for (size_t edge = 0; edge < m; ++edge) {
        const int64_t u = values[3 + 3 * edge];
        const int64_t v = values[4 + 3 * edge];
        const int64_t w = values[5 + 3 * edge];
        if (u < 0 || u >= raw_n || v < 0 || v >= raw_n || w < 0 || w > 1000)
            return -1;
        to[edge] = (int)v;
        weight[edge] = w;
        next[edge] = head[(size_t)u];
        head[(size_t)u] = (int)edge;
    }

    int64_t distance[MAX_VERTICES] = {0};
    uint8_t reachable[MAX_VERTICES] = {0}, queued[MAX_VERTICES] = {0};
    uint8_t removed_before[MAX_VERTICES] = {0};
    int deque[MAX_VERTICES];
    size_t front = 0, size = 1;
    const size_t source = (size_t)raw_source;
    deque[0] = (int)source;
    distance[source] = 0;
    reachable[source] = queued[source] = 1;

    while (size != 0) {
        const int vertex = deque[front];
        front = (front + 1) % n;
        --size;
        queued[(size_t)vertex] = 0;
        removed_before[(size_t)vertex] = 1;
        for (int edge = head[(size_t)vertex]; edge != -1; edge = next[edge]) {
            const int neighbor = to[edge];
            const int64_t candidate = distance[(size_t)vertex] + weight[edge];
            if (!reachable[(size_t)neighbor] || candidate < distance[(size_t)neighbor]) {
                distance[(size_t)neighbor] = candidate;
                reachable[(size_t)neighbor] = 1;
                if (!queued[(size_t)neighbor]) {
                    if (removed_before[(size_t)neighbor]) {
                        front = (front + n - 1) % n;
                        deque[front] = neighbor;
                    } else {
                        deque[(front + size) % n] = neighbor;
                    }
                    ++size;
                    queued[(size_t)neighbor] = 1;
                }
            }
        }
    }

    const size_t byte_count = 8 * n;
    if (output == NULL || capacity < byte_count) return -2;
    for (size_t vertex = 0; vertex < n; ++vertex)
        store_i64_le(output, 8 * vertex, reachable[vertex] ? distance[vertex] : -1);
    return (int64_t)byte_count;
}
