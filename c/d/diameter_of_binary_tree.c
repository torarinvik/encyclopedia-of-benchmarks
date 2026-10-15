/* Count the path through the selected node, matching Node.diameter(). */
#include <stddef.h>
#include <stdint.h>

#define MAX_NODE_COUNT 1023
#define ERROR_SENTINEL INT64_C(-2000000000)

static int64_t height_and_check(const int64_t *nodes, size_t count, int64_t node,
                                uint8_t *seen, size_t *visited)
{
    if (node == -1) return 0;
    if (node < 0 || (uint64_t)node >= count) return ERROR_SENTINEL;
    const size_t index = (size_t)node;
    if (seen[index]) return ERROR_SENTINEL;
    seen[index] = 1;
    ++*visited;
    const int64_t left = nodes[3 * index + 1];
    const int64_t right = nodes[3 * index + 2];
    if (left < -1 || right < -1 ||
        (left >= 0 && (uint64_t)left >= count) ||
        (right >= 0 && (uint64_t)right >= count)) return ERROR_SENTINEL;
    const int64_t left_height = height_and_check(nodes, count, left, seen, visited);
    if (left_height == ERROR_SENTINEL) return ERROR_SENTINEL;
    const int64_t right_height = height_and_check(nodes, count, right, seen, visited);
    if (right_height == ERROR_SENTINEL) return ERROR_SENTINEL;
    return 1 + (left_height > right_height ? left_height : right_height);
}

int64_t diameter_of_binary_tree(const int64_t *nodes, size_t node_count, int64_t root_index)
{
    if (nodes == NULL || node_count == 0 || node_count > MAX_NODE_COUNT ||
        root_index < 0 || (uint64_t)root_index >= node_count) return -1;
    uint8_t seen[MAX_NODE_COUNT] = {0};
    size_t visited = 0;
    const size_t root = (size_t)root_index;
    const int64_t left = nodes[3 * root + 1];
    const int64_t right = nodes[3 * root + 2];
    if (left < -1 || right < -1 ||
        (left >= 0 && (uint64_t)left >= node_count) ||
        (right >= 0 && (uint64_t)right >= node_count)) return -1;
    seen[root] = 1;
    visited = 1;
    const int64_t left_height = height_and_check(nodes, node_count, left, seen, &visited);
    if (left_height == ERROR_SENTINEL) return -1;
    const int64_t right_height = height_and_check(nodes, node_count, right, seen, &visited);
    if (right_height == ERROR_SENTINEL || visited != node_count) return -1;
    return left_height + right_height + 1;
}
