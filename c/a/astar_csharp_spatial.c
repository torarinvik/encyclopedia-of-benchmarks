#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_NODES 16
#define MAX_EDGES 15

typedef struct { double x, y, multiplier, current, estimated; int traversable, state, parent; } Node;

static double distance_between(const Node *a, const Node *b) {
    const double dx = a->x - b->x, dy = a->y - b->y;
    return sqrt(dx * dx + dy * dy);
}

static double total_cost(const Node *nodes, int index) {
    return nodes[index].current + nodes[index].estimated;
}

static void enqueue(int *heap, int *count, int value, const Node *nodes) {
    int i = (*count)++;
    while (i > 0) {
        const int parent = (i - 1) / 2;
        if (total_cost(nodes, heap[parent]) <= total_cost(nodes, value)) break;
        heap[i] = heap[parent];
        i = parent;
    }
    heap[i] = value;
}

static int dequeue(int *heap, int *count, const Node *nodes) {
    const int target = heap[0];
    const int root = heap[--(*count)];
    int i = 0;
    while (i * 2 + 1 < *count) {
        const int left = i * 2 + 1, right = i * 2 + 2;
        const int child = right < *count && total_cost(nodes, heap[right]) < total_cost(nodes, heap[left]) ? right : left;
        if (total_cost(nodes, heap[child]) >= total_cost(nodes, root)) break;
        heap[i] = heap[child];
        i = child;
    }
    if (*count > 0) heap[i] = root;
    return target;
}

static void store_i64_le(int64_t value, uint8_t *output, size_t offset) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t astar_csharp_spatial(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 4) return -1;
    const int64_t n64 = input[0], m64 = input[1], start64 = input[2], goal64 = input[3];
    if (n64 < 2 || n64 > MAX_NODES || m64 != n64 - 1 || start64 < 0 || start64 >= n64 || goal64 < 0 || goal64 >= n64) return -1;
    const int n = (int)n64, m = (int)m64, start = (int)start64, goal = (int)goal64;
    if (length != (size_t)(4 + 4 * n + 2 * m)) return -1;
    Node nodes[MAX_NODES] = {0};
    int parent_count[MAX_NODES] = {0}, seen[MAX_NODES] = {0}, stack[MAX_NODES];
    const size_t edge_offset = (size_t)(4 + 4 * n);
    for (int i = 0; i < n; ++i) {
        const size_t off = (size_t)(4 + 4 * i);
        const int64_t x = input[off], y = input[off + 1], traversable = input[off + 2], multiplier = input[off + 3];
        if (x < -1000 || x > 1000 || y < -1000 || y > 1000 || (traversable != 0 && traversable != 1) || multiplier < 1 || multiplier > 4) return -1;
        nodes[i].x = (double)x; nodes[i].y = (double)y; nodes[i].traversable = (int)traversable; nodes[i].multiplier = (double)multiplier; nodes[i].parent = -1;
        for (int j = 0; j < i; ++j) if (nodes[i].x == nodes[j].x && nodes[i].y == nodes[j].y) return -1;
    }
    for (int e = 0; e < m; ++e) {
        const int64_t from = input[edge_offset + (size_t)(2 * e)], to = input[edge_offset + (size_t)(2 * e + 1)];
        if (from < 0 || from >= n || to < 0 || to >= n || from == to || ++parent_count[to] > 1) return -1;
        for (int previous = 0; previous < e; ++previous) if (input[edge_offset + (size_t)(2 * previous)] == from && input[edge_offset + (size_t)(2 * previous + 1)] == to) return -1;
    }
    if (parent_count[start] != 0) return -1;
    for (int i = 0; i < n; ++i) if (i != start && parent_count[i] != 1) return -1;
    int top = 0, visited = 0;
    stack[top++] = start;
    while (top > 0) {
        const int current = stack[--top];
        if (seen[current]) continue;
        seen[current] = 1; ++visited;
        for (int e = 0; e < m; ++e) if (input[edge_offset + (size_t)(2 * e)] == current) stack[top++] = (int)input[edge_offset + (size_t)(2 * e + 1)];
    }
    if (visited != n) return -1;

    int heap[MAX_NODES], heap_count = 0;
    for (int e = 0; e < m; ++e) if (input[edge_offset + (size_t)(2 * e)] == start) {
        const int node = (int)input[edge_offset + (size_t)(2 * e + 1)];
        if (nodes[node].traversable) {
            nodes[node].current = distance_between(&nodes[start], &nodes[node]) * nodes[node].multiplier;
            nodes[node].estimated = distance_between(&nodes[node], &nodes[goal]);
            enqueue(heap, &heap_count, node, nodes);
        }
    }
    int path[MAX_NODES], path_count = 0;
    while (heap_count > 0) {
        const int current = dequeue(heap, &heap_count, nodes);
        nodes[current].state = 2;
        if (total_cost(nodes, current) == total_cost(nodes, goal)) {
            for (int cursor = goal; cursor >= 0 && path_count < MAX_NODES; cursor = nodes[cursor].parent) path[path_count++] = cursor;
            break;
        }
        for (int e = 0; e < m; ++e) if (input[edge_offset + (size_t)(2 * e)] == current) {
            const int connected = (int)input[edge_offset + (size_t)(2 * e + 1)];
            if (!nodes[connected].traversable || nodes[connected].state == 2) continue;
            if (nodes[connected].state == 0) {
                nodes[connected].parent = current;
                nodes[connected].current = nodes[current].current + distance_between(&nodes[current], &nodes[connected]) * nodes[connected].multiplier;
                nodes[connected].estimated = nodes[connected].current + distance_between(&nodes[connected], &nodes[goal]);
                nodes[connected].state = 1;
                enqueue(heap, &heap_count, connected, nodes);
            } else if (total_cost(nodes, current) != total_cost(nodes, connected)) {
                const double new_current = nodes[current].current + distance_between(&nodes[current], &nodes[connected]);
                const double new_total = new_current + nodes[current].estimated;
                if (new_total < total_cost(nodes, connected)) { nodes[connected].parent = current; nodes[connected].current = new_current; }
            } else return -1;
        }
    }
    const size_t output_bytes = (size_t)path_count * 8;
    if (output_bytes == 0) return 0;
    if (output == NULL || capacity < output_bytes) return -2;
    for (int i = 0; i < path_count; ++i) store_i64_le(path[path_count - 1 - i], output, (size_t)i * 8);
    return (int64_t)output_bytes;
}
