/* Kuhn DFS augmenting-path maximum matching for a bounded bipartite graph. */
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_SIDE 64
#define MAX_EDGES (MAX_SIDE * MAX_SIDE)

static bool try_augment(size_t left, size_t right_count, const bool *adjacency,
                        bool *seen_right, int *pair_right)
{
    for (size_t right = 0; right < right_count; ++right) {
        if (!adjacency[left * MAX_SIDE + right] || seen_right[right]) continue;
        seen_right[right] = true;
        const int mate = pair_right[right];
        if (mate < 0 || try_augment((size_t)mate, right_count, adjacency, seen_right, pair_right)) {
            pair_right[right] = (int)left;
            return true;
        }
    }
    return false;
}

int64_t bipartite_matching_kuhn(const int64_t *input, size_t length)
{
    if (input == NULL || length < 3) return -1;
    if (input[0] < 0 || input[0] > MAX_SIDE || input[1] < 0 || input[1] > MAX_SIDE ||
        input[2] < 0 || input[2] > MAX_EDGES) return -1;
    const size_t left_count = (size_t)input[0];
    const size_t right_count = (size_t)input[1];
    const size_t edge_count = (size_t)input[2];
    if (length != 3 + 2 * edge_count) return -1;
    bool adjacency[MAX_SIDE * MAX_SIDE] = {false};
    for (size_t edge = 0; edge < edge_count; ++edge) {
        const int64_t left = input[3 + 2 * edge], right = input[4 + 2 * edge];
        if (left < 0 || left >= (int64_t)left_count || right < 0 || right >= (int64_t)right_count) return -1;
        adjacency[(size_t)left * MAX_SIDE + (size_t)right] = true;
    }
    int pair_right[MAX_SIDE];
    for (size_t right = 0; right < right_count; ++right) pair_right[right] = -1;
    int64_t matching = 0;
    for (size_t left = 0; left < left_count; ++left) {
        bool seen_right[MAX_SIDE] = {false};
        if (try_augment(left, right_count, adjacency, seen_right, pair_right)) ++matching;
    }
    return matching;
}
