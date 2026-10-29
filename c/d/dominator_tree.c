#include <stddef.h>
#include <stdint.h>

#define MAX_VERTEX_COUNT 63
#define MAX_EDGE_COUNT 2047
#define MAX_INPUT_LENGTH (3 + 2 * MAX_EDGE_COUNT)

static size_t count_bits(uint64_t value)
{
    size_t count = 0;
    while (value != 0) {
        value &= value - 1;
        ++count;
    }
    return count;
}

int64_t dominator_tree(const int64_t *input, size_t length,
                       uint8_t *output, size_t output_capacity)
{
    if (input == NULL || length < 3 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > MAX_VERTEX_COUNT ||
        input[1] < 0 || input[1] >= input[0] ||
        input[2] < 0 || input[2] > MAX_EDGE_COUNT) return -1;
    const size_t vertex_count = (size_t)input[0];
    const size_t root = (size_t)input[1];
    const size_t edge_count = (size_t)input[2];
    if (length != 3 + 2 * edge_count) return -1;

    uint64_t outgoing[MAX_VERTEX_COUNT] = {0};
    for (size_t edge = 0; edge < edge_count; ++edge) {
        const int64_t from_value = input[3 + 2 * edge];
        const int64_t to_value = input[4 + 2 * edge];
        if (from_value < 0 || to_value < 0 ||
            from_value >= (int64_t)vertex_count || to_value >= (int64_t)vertex_count) return -1;
        outgoing[(size_t)from_value] |= UINT64_C(1) << (size_t)to_value;
    }

    uint64_t reachable = UINT64_C(1) << root;
    uint64_t frontier = reachable;
    while (frontier != 0) {
        uint64_t discovered = 0;
        for (size_t vertex = 0; vertex < vertex_count; ++vertex)
            if ((frontier & (UINT64_C(1) << vertex)) != 0) discovered |= outgoing[vertex];
        discovered &= ~reachable;
        reachable |= discovered;
        frontier = discovered;
    }

    uint64_t dominators[MAX_VERTEX_COUNT] = {0};
    dominators[root] = UINT64_C(1) << root;
    for (size_t vertex = 0; vertex < vertex_count; ++vertex)
        if ((reachable & (UINT64_C(1) << vertex)) != 0 && vertex != root)
            dominators[vertex] = reachable;

    int changed;
    do {
        changed = 0;
        for (size_t vertex = 0; vertex < vertex_count; ++vertex) {
            const uint64_t vertex_bit = UINT64_C(1) << vertex;
            if ((reachable & vertex_bit) == 0 || vertex == root) continue;
            uint64_t common = reachable;
            for (size_t predecessor = 0; predecessor < vertex_count; ++predecessor)
                if ((reachable & (UINT64_C(1) << predecessor)) != 0 &&
                    (outgoing[predecessor] & vertex_bit) != 0)
                    common &= dominators[predecessor];
            const uint64_t updated = common | vertex_bit;
            if (updated != dominators[vertex]) {
                dominators[vertex] = updated;
                changed = 1;
            }
        }
    } while (changed);

    if (output == NULL || output_capacity < vertex_count) return -2;
    for (size_t vertex = 0; vertex < vertex_count; ++vertex) {
        if ((reachable & (UINT64_C(1) << vertex)) == 0) {
            output[vertex] = UINT8_MAX;
        } else if (vertex == root) {
            output[vertex] = (uint8_t)root;
        } else {
            const uint64_t strict = dominators[vertex] & ~(UINT64_C(1) << vertex);
            size_t best = root;
            size_t best_depth = 0;
            for (size_t candidate = 0; candidate < vertex_count; ++candidate) {
                if ((strict & (UINT64_C(1) << candidate)) == 0) continue;
                const size_t depth = count_bits(dominators[candidate]);
                if (depth > best_depth) {
                    best = candidate;
                    best_depth = depth;
                }
            }
            output[vertex] = (uint8_t)best;
        }
    }
    return (int64_t)vertex_count;
}
