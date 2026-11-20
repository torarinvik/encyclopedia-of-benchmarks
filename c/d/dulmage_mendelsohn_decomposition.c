/* Clean-room Dulmage--Mendelsohn decomposition of a bipartite graph. */
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

enum { MAX_SIDE = 6, MAX_VERTICES = 12, MAX_EDGES = 36, MAX_PARSEABLE = 76 };

static bool augment(const uint16_t *adj_left, int left, int right_count,
                    bool *seen_right, int *match_right) {
    for (int right = 0; right < right_count; ++right) {
        const uint16_t bit = (uint16_t)(1u << right);
        if (!(adj_left[left] & bit) || seen_right[right]) continue;
        seen_right[right] = true;
        const int mate = match_right[right];
        if (mate < 0 || augment(adj_left, mate, right_count, seen_right, match_right)) {
            match_right[right] = left;
            return true;
        }
    }
    return false;
}

static int maximum_matching(const uint16_t *adj_left, int left_count,
                            int right_count, int *match_left, int *match_right) {
    for (int right = 0; right < right_count; ++right) match_right[right] = -1;
    int size = 0;
    for (int left = 0; left < left_count; ++left) {
        bool seen_right[MAX_SIDE] = {false};
        if (augment(adj_left, left, right_count, seen_right, match_right)) ++size;
    }
    for (int left = 0; left < left_count; ++left) match_left[left] = -1;
    for (int right = 0; right < right_count; ++right)
        if (match_right[right] >= 0) match_left[match_right[right]] = right;
    return size;
}

int64_t dulmage_mendelsohn_decomposition(const int64_t *input, size_t length) {
    if (input == NULL || length < 3 || length > MAX_PARSEABLE) return -1;
    const int64_t left64 = input[0], right64 = input[1], edges64 = input[2];
    if (left64 < 0 || left64 > MAX_SIDE || right64 < 0 || right64 > MAX_SIDE ||
        left64 + right64 < 1 || edges64 < 0 || edges64 > MAX_EDGES ||
        edges64 > left64 * right64 || length != 3 + 2 * (size_t)edges64) return -1;
    const int left_count = (int)left64, right_count = (int)right64;
    const int total = left_count + right_count, edge_count = (int)edges64;
    uint16_t adj_left[MAX_SIDE] = {0};
    uint16_t adj_global[MAX_VERTICES] = {0};
    for (int edge = 0; edge < edge_count; ++edge) {
        const int64_t u64 = input[3 + 2 * edge], v64 = input[4 + 2 * edge];
        if (u64 < 0 || u64 >= left_count || v64 < 0 || v64 >= right_count) return -1;
        const int u = (int)u64, v = (int)v64, global_right = left_count + (int)v64;
        const uint16_t right_bit = (uint16_t)(1u << v);
        if (adj_left[u] & right_bit) return -1;
        adj_left[u] |= right_bit;
        adj_global[u] |= (uint16_t)(1u << global_right);
        adj_global[global_right] |= (uint16_t)(1u << u);
    }

    int match_left[MAX_SIDE], match_right[MAX_SIDE];
    const int matching_size = maximum_matching(adj_left, left_count, right_count,
                                                match_left, match_right);
    bool seen[2 * MAX_VERTICES] = {false};
    int queue[2 * MAX_VERTICES], head = 0, tail = 0;
    for (int left = 0; left < left_count; ++left) if (match_left[left] < 0) {
        const int state = 2 * left;
        seen[state] = true; queue[tail++] = state;
    }
    for (int right = 0; right < right_count; ++right) if (match_right[right] < 0) {
        const int state = 2 * (left_count + right);
        seen[state] = true; queue[tail++] = state;
    }
    while (head < tail) {
        const int state = queue[head++];
        const int vertex = state / 2, parity = state & 1;
        for (int neighbor = 0; neighbor < total; ++neighbor) {
            if (!(adj_global[vertex] & (uint16_t)(1u << neighbor))) continue;
            const bool matched = vertex < left_count
                ? match_left[vertex] == neighbor - left_count
                : match_right[vertex - left_count] == neighbor;
            if ((parity == 0 && matched) || (parity == 1 && !matched)) continue;
            const int next_state = 2 * neighbor + 1 - parity;
            if (!seen[next_state]) { seen[next_state] = true; queue[tail++] = next_state; }
        }
    }

    uint64_t packed = (uint64_t)matching_size << 32;
    for (int vertex = 0; vertex < total; ++vertex) {
        const int class_code = seen[2 * vertex] ? 0 : seen[2 * vertex + 1] ? 1 : 2;
        packed |= (uint64_t)class_code << (2 * vertex);
    }
    return (int64_t)packed;
}
