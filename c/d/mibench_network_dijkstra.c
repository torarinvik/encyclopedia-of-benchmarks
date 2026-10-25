#include <stddef.h>
#include <stdint.h>

#define MAX_NODES 6
#define MAX_QUEUE_ITEMS 1024
#define NONE 9999

typedef struct { int node; int64_t distance; int previous; } QueueItem;

int64_t mibench_network_dijkstra(const int64_t *input, size_t length) {
    if (input == NULL || length < 3) return -1;
    const int64_t node_value = input[0];
    if (node_value < 1 || node_value > MAX_NODES) return -1;
    const size_t nodes = (size_t)node_value;
    if (length != 2 + nodes * nodes) return -1;
    const int64_t source_value = input[1];
    if (source_value < 0 || (uint64_t)source_value >= nodes) return -1;
    for (size_t i = 0; i < nodes * nodes; ++i) {
        const int64_t cost = input[2 + i];
        if (cost != NONE && (cost < 0 || cost > 31)) return -1;
    }

    int64_t distance[MAX_NODES];
    uint8_t reachable[MAX_NODES] = {0};
    QueueItem queue[MAX_QUEUE_ITEMS];
    for (size_t i = 0; i < nodes; ++i) distance[i] = NONE;
    const int source = (int)source_value;
    distance[source] = 0;
    reachable[source] = 1;
    size_t head = 0, tail = 0;
    queue[tail++] = (QueueItem){source, 0, NONE};
    while (head < tail) {
        const QueueItem item = queue[head++];
        for (size_t destination = 0; destination < nodes; ++destination) {
            const int64_t cost = input[2 + (size_t)item.node * nodes + destination];
            if (cost == NONE) continue;
            const int64_t candidate = item.distance + cost;
            if (!reachable[destination] || distance[destination] > candidate) {
                distance[destination] = candidate;
                reachable[destination] = 1;
                if (tail >= MAX_QUEUE_ITEMS) return -2;
                queue[tail++] = (QueueItem){(int)destination, candidate, item.node};
            }
        }
    }
    int64_t checksum = 0;
    uint64_t mask = 0;
    for (size_t node = 0; node < nodes; ++node) {
        if (reachable[node]) {
            checksum += (int64_t)(node + 1) * distance[node];
            mask |= UINT64_C(1) << node;
        }
    }
    return checksum + (int64_t)mask;
}
