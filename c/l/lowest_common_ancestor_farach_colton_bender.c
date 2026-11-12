#include <stddef.h>
#include <stdint.h>

#define MAX_NODES 256
#define MAX_QUERIES 1024
#define MAX_ARCS 510
#define MAX_EULER (2 * MAX_NODES - 1)
#define MAX_MICRO 4
#define SHAPE_COUNT 8
#define MAX_BLOCKS 128
#define MAX_LEVELS 8

static uint16_t shallower(uint16_t a, uint16_t b, const uint16_t *depth) {
    if (depth[a] != depth[b]) return depth[a] < depth[b] ? a : b;
    return a < b ? a : b;
}

static uint16_t range_minimum(uint16_t first, uint16_t last, size_t euler_count,
    size_t block_size, const uint16_t *depth, const uint8_t *pattern,
    const uint8_t micro[SHAPE_COUNT][MAX_MICRO][MAX_MICRO],
    const uint16_t macro[MAX_LEVELS][MAX_BLOCKS], const uint8_t *logs) {
    const size_t block_a = first / block_size, block_b = last / block_size;
    const size_t offset_a = first % block_size, offset_b = last % block_size;
    if (block_a == block_b)
        return (uint16_t)(block_a * block_size + micro[pattern[block_a]][offset_a][offset_b]);
    const size_t base_a = block_a * block_size, base_b = block_b * block_size;
    const size_t len_a = (euler_count - base_a < block_size) ? euler_count - base_a : block_size;
    const size_t len_b = (euler_count - base_b < block_size) ? euler_count - base_b : block_size;
    uint16_t best = (uint16_t)(base_a + micro[pattern[block_a]][offset_a][len_a - 1]);
    best = shallower(best, (uint16_t)(base_b + micro[pattern[block_b]][0][offset_b]), depth);
    if (block_b > block_a + 1) {
        const size_t lo = block_a + 1, hi = block_b - 1;
        const size_t count = hi - lo + 1, level = logs[count], span = (size_t)1 << level;
        best = shallower(best, macro[level][lo], depth);
        best = shallower(best, macro[level][hi - span + 1], depth);
    }
    return best;
}

int64_t lowest_common_ancestor_farach_colton_bender(const int64_t *input, size_t length,
    uint8_t *output, size_t output_capacity) {
    if (input == NULL || length < 4) return -1;
    if (input[0] < 1 || input[0] > MAX_NODES) return -1;
    const size_t node_count = (size_t)input[0];
    if (input[1] < 0 || input[1] >= (int64_t)node_count ||
        input[2] != (int64_t)(node_count - 1) || input[3] < 0 || input[3] > MAX_QUERIES) return -1;
    const size_t edge_count = (size_t)input[2], query_count = (size_t)input[3];
    const size_t query_offset = 4 + 2 * edge_count;
    if (length != query_offset + 2 * query_count) return -1;
    const size_t root = (size_t)input[1];

    int head[MAX_NODES], arc_to[MAX_ARCS], arc_next[MAX_ARCS];
    int parent[MAX_NODES], tree_depth[MAX_NODES], first[MAX_NODES];
    uint16_t euler[MAX_EULER], euler_depth[MAX_EULER];
    int stack_node[MAX_NODES], stack_arc[MAX_NODES];
    for (size_t node = 0; node < node_count; ++node) {
        head[node] = -1;
        parent[node] = -2;
    }
    size_t arcs = 0;
    for (size_t edge = 0; edge < edge_count; ++edge) {
        const int64_t u = input[4 + 2 * edge], v = input[5 + 2 * edge];
        if (u < 0 || u >= (int64_t)node_count || v < 0 || v >= (int64_t)node_count || u == v) return -1;
        const size_t a = (size_t)u, b = (size_t)v;
        arc_to[arcs] = (int)b; arc_next[arcs] = head[a]; head[a] = (int)arcs++;
        arc_to[arcs] = (int)a; arc_next[arcs] = head[b]; head[b] = (int)arcs++;
    }
    for (size_t query = 0; query < query_count; ++query)
        for (size_t side = 0; side < 2; ++side) {
            const int64_t node = input[query_offset + 2 * query + side];
            if (node < 0 || node >= (int64_t)node_count) return -1;
        }

    size_t euler_count = 1, top = 1, reached = 1;
    parent[root] = -1; tree_depth[root] = 0; first[root] = 0;
    euler[0] = (uint16_t)root; euler_depth[0] = 0;
    stack_node[0] = (int)root; stack_arc[0] = head[root];
    while (top > 0) {
        const size_t slot = top - 1, node = (size_t)stack_node[slot];
        const int arc = stack_arc[slot];
        if (arc < 0) {
            --top;
            if (top > 0) {
                const size_t up = (size_t)stack_node[top - 1];
                euler[euler_count] = (uint16_t)up;
                euler_depth[euler_count++] = (uint16_t)tree_depth[up];
            }
            continue;
        }
        stack_arc[slot] = arc_next[arc];
        const size_t neighbor = (size_t)arc_to[arc];
        if ((int)neighbor == parent[node]) continue;
        if (parent[neighbor] != -2) return -1;
        parent[neighbor] = (int)node;
        tree_depth[neighbor] = tree_depth[node] + 1;
        first[neighbor] = (int)euler_count;
        euler[euler_count] = (uint16_t)neighbor;
        euler_depth[euler_count++] = (uint16_t)tree_depth[neighbor];
        ++reached;
        stack_node[top] = (int)neighbor; stack_arc[top] = head[neighbor]; ++top;
    }
    if (reached != node_count) return -1;
    if (output_capacity < query_count || (query_count != 0 && output == NULL)) return -2;

    size_t logarithm = 0;
    for (size_t value = euler_count; value > 1; value >>= 1) ++logarithm;
    size_t block_size = logarithm / 2;
    if (block_size < 1) block_size = 1;
    const size_t block_count = (euler_count + block_size - 1) / block_size;
    uint8_t micro[SHAPE_COUNT][MAX_MICRO][MAX_MICRO] = {{{0}}};
    uint8_t pattern[MAX_BLOCKS] = {0}, logs[MAX_BLOCKS + 1] = {0};
    uint16_t macro[MAX_LEVELS][MAX_BLOCKS] = {{0}};
    const size_t shape_count = (size_t)1 << (block_size - 1);
    for (size_t shape = 0; shape < shape_count; ++shape) {
        int relative[MAX_MICRO] = {0};
        for (size_t step = 0; step + 1 < block_size; ++step)
            relative[step + 1] = relative[step] + (((shape >> step) & 1) ? 1 : -1);
        for (size_t left = 0; left < block_size; ++left)
            for (size_t right = left; right < block_size; ++right) {
                size_t best = left;
                for (size_t at = left + 1; at <= right; ++at)
                    if (relative[at] < relative[best]) best = at;
                micro[shape][left][right] = (uint8_t)best;
            }
    }
    for (size_t block = 0; block < block_count; ++block) {
        const size_t base = block * block_size;
        const size_t end = (euler_count - base < block_size) ? euler_count : base + block_size;
        uint16_t best = (uint16_t)base;
        for (size_t at = base; at + 1 < end; ++at) {
            if (euler_depth[at + 1] > euler_depth[at]) pattern[block] |= (uint8_t)(1u << (at - base));
            best = shallower(best, (uint16_t)(at + 1), euler_depth);
        }
        macro[0][block] = best;
    }
    for (size_t count = 2; count <= block_count; ++count) logs[count] = (uint8_t)(logs[count / 2] + 1);
    size_t macro_levels = 1;
    while (((size_t)1 << macro_levels) <= block_count && macro_levels < MAX_LEVELS) {
        const size_t half = (size_t)1 << (macro_levels - 1), span = 2 * half;
        for (size_t block = 0; block + span <= block_count; ++block)
            macro[macro_levels][block] = shallower(macro[macro_levels - 1][block],
                macro[macro_levels - 1][block + half], euler_depth);
        ++macro_levels;
    }

    uint8_t answers[MAX_QUERIES];
    for (size_t query = 0; query < query_count; ++query) {
        size_t u = (size_t)input[query_offset + 2 * query];
        size_t v = (size_t)input[query_offset + 2 * query + 1];
        size_t left = (size_t)first[u], right = (size_t)first[v];
        if (left > right) { const size_t temp = left; left = right; right = temp; }
        const uint16_t at = range_minimum((uint16_t)left, (uint16_t)right, euler_count,
            block_size, euler_depth, pattern, micro, macro, logs);
        answers[query] = (uint8_t)euler[at];
    }
    for (size_t query = 0; query < query_count; ++query) output[query] = answers[query];
    return (int64_t)query_count;
}
