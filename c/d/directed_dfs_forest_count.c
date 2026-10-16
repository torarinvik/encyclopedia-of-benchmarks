#include <stddef.h>
#include <stdint.h>

#define MAX_EDGE_COUNT 64
#define MAX_VERTEX_ID 63
#define MAX_NODE_COUNT 128
#define MAX_INPUT_LENGTH (1 + 2 * MAX_EDGE_COUNT)

static size_t find_last_node(int64_t label, const int64_t *labels, size_t node_count)
{
    size_t found = MAX_NODE_COUNT;
    for (size_t node = 0; node < node_count; ++node) {
        if (labels[node] == label) found = node;
    }
    return found;
}

static void visit(size_t current, size_t edge_count, const size_t *edge_starts,
                  const size_t *edge_ends, uint8_t *visited)
{
    visited[current] = 1;
    for (size_t edge = 0; edge < edge_count; ++edge) {
        const size_t destination = edge_ends[edge];
        if (edge_starts[edge] == current && !visited[destination])
            visit(destination, edge_count, edge_starts, edge_ends, visited);
    }
}

int64_t directed_dfs_forest_count(const int64_t *input, size_t length)
{
    if (input == NULL || length < 1 || length > MAX_INPUT_LENGTH + 1) return -1;
    const int64_t edge_count_value = input[0];
    if (edge_count_value < 0 || edge_count_value > MAX_EDGE_COUNT) return -1;
    const size_t edge_count = (size_t)edge_count_value;
    if (length != 1 + 2 * edge_count) return -1;

    int64_t labels[MAX_NODE_COUNT] = {0};
    size_t edge_starts[MAX_EDGE_COUNT] = {0}, edge_ends[MAX_EDGE_COUNT] = {0};
    size_t node_count = 0;
    for (size_t edge = 0; edge < edge_count; ++edge) {
        const int64_t start_label = input[1 + 2 * edge];
        const int64_t end_label = input[2 + 2 * edge];
        if (start_label < 0 || start_label > MAX_VERTEX_ID
            || end_label < 0 || end_label > MAX_VERTEX_ID) return -1;

        size_t start = find_last_node(start_label, labels, node_count);
        size_t end;
        if (start_label == end_label) {
            if (start == MAX_NODE_COUNT) {
                start = node_count;
                labels[node_count++] = start_label;
            }
            end = node_count;
            labels[node_count++] = end_label;
        } else {
            end = find_last_node(end_label, labels, node_count);
            if (start == MAX_NODE_COUNT) {
                start = node_count;
                labels[node_count++] = start_label;
            }
            if (end == MAX_NODE_COUNT) {
                end = node_count;
                labels[node_count++] = end_label;
            }
        }
        edge_starts[edge] = start;
        edge_ends[edge] = end;
    }

    uint8_t marked[MAX_NODE_COUNT] = {0};
    int64_t roots = 0;
    for (size_t root = 0; root < node_count; ++root) {
        if (marked[root]) continue;
        uint8_t visited[MAX_NODE_COUNT] = {0};
        visit(root, edge_count, edge_starts, edge_ends, visited);
        for (size_t node = 0; node < node_count; ++node)
            if (visited[node]) marked[node] = 1;
        ++roots;
    }
    return roots;
}
