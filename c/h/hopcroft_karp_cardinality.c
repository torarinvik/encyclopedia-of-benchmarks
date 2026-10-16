/* Hopcroft-Karp maximum cardinality matching for a bounded bipartite graph. */
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_SIDE 64
#define MAX_EDGES (MAX_SIDE * MAX_SIDE)
#define INF_DISTANCE 1000000

static bool dfs_augment(size_t left, size_t right_count, const bool *adjacency,
                        int *distance, int nil_distance, int *pair_left,
                        int *pair_right)
{
    for (size_t right = 0; right < right_count; ++right) {
        if (!adjacency[left * MAX_SIDE + right]) continue;
        const int mate = pair_right[right];
        if (mate < 0) {
            if (distance[left] + 1 != nil_distance) continue;
            pair_left[left] = (int)right;
            pair_right[right] = (int)left;
            return true;
        }
        if (distance[(size_t)mate] == distance[left] + 1 &&
            dfs_augment((size_t)mate, right_count, adjacency, distance,
                        nil_distance, pair_left, pair_right)) {
            pair_left[left] = (int)right;
            pair_right[right] = (int)left;
            return true;
        }
    }
    distance[left] = INF_DISTANCE;
    return false;
}

static int bfs_layers(size_t left_count, size_t right_count, const bool *adjacency,
                      const int *pair_right, int *distance)
{
    size_t queue[MAX_SIDE];
    size_t head = 0, tail = 0;
    for (size_t left = 0; left < left_count; ++left) {
        if (distance[left] == -1) {
            distance[left] = 0;
            queue[tail++] = left;
        }
    }
    int nil_distance = INF_DISTANCE;
    while (head < tail) {
        const size_t left = queue[head++];
        if (distance[left] + 1 > nil_distance) continue;
        for (size_t right = 0; right < right_count; ++right) {
            if (!adjacency[left * MAX_SIDE + right]) continue;
            const int mate = pair_right[right];
            if (mate < 0) {
                if (distance[left] + 1 < nil_distance) nil_distance = distance[left] + 1;
            } else if (distance[(size_t)mate] == -1) {
                distance[(size_t)mate] = distance[left] + 1;
                queue[tail++] = (size_t)mate;
            }
        }
    }
    return nil_distance;
}

int64_t hopcroft_karp_cardinality(const int64_t *input, size_t length)
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
        const int64_t left = input[3 + 2 * edge];
        const int64_t right = input[4 + 2 * edge];
        if (left < 0 || left >= (int64_t)left_count ||
            right < 0 || right >= (int64_t)right_count) return -1;
        adjacency[(size_t)left * MAX_SIDE + (size_t)right] = true;
    }

    int pair_left[MAX_SIDE], pair_right[MAX_SIDE], distance[MAX_SIDE];
    for (size_t left = 0; left < left_count; ++left) pair_left[left] = -1;
    for (size_t right = 0; right < right_count; ++right) pair_right[right] = -1;
    int64_t matching = 0;
    for (;;) {
        for (size_t left = 0; left < left_count; ++left)
            distance[left] = pair_left[left] < 0 ? 0 : -1;
        const int nil_distance = bfs_layers(left_count, right_count, adjacency, pair_right, distance);
        if (nil_distance == INF_DISTANCE) break;
        for (size_t left = 0; left < left_count; ++left) {
            if (pair_left[left] < 0 &&
                dfs_augment(left, right_count, adjacency, distance, nil_distance,
                            pair_left, pair_right)) ++matching;
        }
    }
    return matching;
}
