/* Return the edge that first closes the cycle under input-order union-find. */
#include <stddef.h>
#include <stdint.h>

#define MAX_VERTICES 1000

static int32_t find_root(int32_t *parents, int32_t node)
{
    int32_t root = node;
    while (parents[root] != root) root = parents[root];
    while (parents[node] != node) {
        const int32_t next = parents[node];
        parents[node] = root;
        node = next;
    }
    return root;
}

int64_t redundant_connection(const int64_t *values, size_t length,
                             uint8_t *output, size_t output_capacity)
{
    if (length < 6 || length > 2 * MAX_VERTICES || (length & 1) != 0 || values == NULL) return -1;
    const size_t edge_count = length / 2;
    for (size_t index = 0; index < length; ++index)
        if (values[index] < 1 || values[index] > (int64_t)edge_count) return -1;
    for (size_t edge = 0; edge < edge_count; ++edge)
        if (values[2 * edge] == values[2 * edge + 1]) return -1;

    int32_t parents[MAX_VERTICES + 1];
    for (size_t node = 0; node <= edge_count; ++node) parents[node] = (int32_t)node;
    int64_t redundant_left = 0, redundant_right = 0;
    size_t redundant_count = 0;
    for (size_t edge = 0; edge < edge_count; ++edge) {
        const int32_t left = (int32_t)values[2 * edge];
        const int32_t right = (int32_t)values[2 * edge + 1];
        const int32_t left_root = find_root(parents, left);
        const int32_t right_root = find_root(parents, right);
        if (left_root == right_root) {
            redundant_left = left;
            redundant_right = right;
            ++redundant_count;
        } else {
            parents[left_root] = right_root;
        }
    }
    if (redundant_count != 1) return -1;
    if (output_capacity < 8 || output == NULL) return -2;
    const uint32_t endpoints[2] = {(uint32_t)redundant_left, (uint32_t)redundant_right};
    for (size_t endpoint = 0; endpoint < 2; ++endpoint)
        for (size_t byte = 0; byte < 4; ++byte)
            output[endpoint * 4 + byte] = (uint8_t)(endpoints[endpoint] >> (byte * 8));
    return 2;
}
