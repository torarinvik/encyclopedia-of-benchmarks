/* DFS that visits a successor only after all of its predecessors are visited. */
#include <stddef.h>
#include <stdint.h>

enum { MAX_NODES = 16, MAX_INPUT_VALUES = 2 + MAX_NODES * MAX_NODES,
       MAX_EVENTS = MAX_NODES + MAX_NODES * (MAX_NODES - 1) / 2,
       MAX_OUTPUT_BYTES = 12 * MAX_EVENTS };

typedef struct { int32_t type, node, order; } event_t;

static int visit_node(size_t node, size_t count,
                      const uint8_t adjacent[MAX_NODES][MAX_NODES],
                      const uint8_t predecessors[MAX_NODES][MAX_NODES],
                      uint8_t visited[MAX_NODES], event_t events[MAX_EVENTS],
                      size_t *event_count, int32_t *next_order)
{
    if (*event_count >= MAX_EVENTS) return 0;
    visited[node] = 1;
    events[(*event_count)++] = (event_t){1, (int32_t)node, (*next_order)++};
    for (size_t child = 0; child < count; ++child) {
        if (!adjacent[node][child] || visited[child]) continue;
        int all_visited = 1;
        for (size_t parent = 0; parent < count; ++parent)
            if (predecessors[child][parent] && !visited[parent]) { all_visited = 0; break; }
        if (all_visited) {
            if (!visit_node(child, count, adjacent, predecessors, visited, events, event_count, next_order)) return 0;
        } else {
            if (*event_count >= MAX_EVENTS) return 0;
            events[(*event_count)++] = (event_t){0, (int32_t)child, -1};
        }
    }
    return 1;
}

static void write_i32_le(uint8_t *output, size_t offset, int32_t value)
{
    uint32_t bits = (uint32_t)value;
    for (size_t byte = 0; byte < 4; ++byte) output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t predecessor_constrained_dfs(const int64_t *input, size_t length,
                                    uint8_t *output, size_t output_capacity)
{
    if (input == NULL || length < 2 || length > MAX_INPUT_VALUES) return -1;
    int64_t raw_count = input[0], raw_start = input[1];
    if (raw_count < 1 || raw_count > MAX_NODES || raw_start < 0 || raw_start >= raw_count ||
        length != 2 + (size_t)raw_count * (size_t)raw_count) return -1;
    size_t count = (size_t)raw_count, indegree[MAX_NODES] = {0}, queue[MAX_NODES];
    uint8_t adjacent[MAX_NODES][MAX_NODES] = {{0}}, predecessors[MAX_NODES][MAX_NODES] = {{0}};
    for (size_t from = 0; from < count; ++from) {
        for (size_t to = 0; to < count; ++to) {
            int64_t bit = input[2 + from * count + to];
            if (bit != 0 && bit != 1) return -1;
            if (from == to && bit != 0) return -1;
            if (bit) { adjacent[from][to] = 1; predecessors[to][from] = 1; ++indegree[to]; }
        }
    }
    size_t head = 0, tail = 0;
    for (size_t node = 0; node < count; ++node) if (indegree[node] == 0) queue[tail++] = node;
    while (head < tail) {
        size_t node = queue[head++];
        for (size_t child = 0; child < count; ++child)
            if (adjacent[node][child] && --indegree[child] == 0) queue[tail++] = child;
    }
    if (tail != count) return -1;
    uint8_t visited[MAX_NODES] = {0};
    event_t events[MAX_EVENTS];
    size_t event_count = 0;
    int32_t next_order = 0;
    if (!visit_node((size_t)raw_start, count, adjacent, predecessors, visited, events, &event_count, &next_order)) return -1;
    size_t byte_count = 12 * event_count;
    if (output == NULL || output_capacity < byte_count) return -2;
    for (size_t i = 0; i < event_count; ++i) {
        write_i32_le(output, 12 * i, events[i].type);
        write_i32_le(output, 12 * i + 4, events[i].node);
        write_i32_le(output, 12 * i + 8, events[i].order);
    }
    return (int64_t)byte_count;
}
