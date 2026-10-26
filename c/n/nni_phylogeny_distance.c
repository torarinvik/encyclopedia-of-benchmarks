#include <stddef.h>
#include <stdint.h>

#define MAX_LEAVES 7
#define MAX_EDGES 11
#define MAX_INPUT 23
#define MAX_STATES 945
#define MAX_DEGREE 8

static void store_i64_le(uint8_t *output, size_t offset, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & 255U);
        bits >>= 8;
    }
}

static size_t bit_count(uint16_t value, size_t n)
{
    size_t count = 0;
    for (size_t bit = 0; bit < n; ++bit) count += (size_t)((value >> bit) & 1U);
    return count;
}

static int valid_tree(const int64_t *input, size_t offset, size_t n, size_t edges)
{
    uint16_t splits[MAX_EDGES] = {0};
    uint16_t internal[MAX_EDGES] = {0};
    size_t internal_count = 0;
    uint16_t universe = (uint16_t)(((uint16_t)1U << n) - 1U);
    for (size_t i = 0; i < edges; ++i) {
        int64_t raw = input[offset + i];
        if (raw <= 0 || (uint64_t)raw >= universe || (raw & 1) != 0) return 0;
        splits[i] = (uint16_t)raw;
        for (size_t earlier = 0; earlier < i; ++earlier) if (splits[earlier] == splits[i]) return 0;
        size_t count = bit_count(splits[i], n);
        if (count == 1 || count == n - 1) {
            if (count == n - 1 && splits[i] != (uint16_t)(universe ^ 1U)) return 0;
        } else if (count >= 2 && count <= n - 2) {
            internal[internal_count++] = splits[i];
        } else {
            return 0;
        }
    }
    if (internal_count != n - 3) return 0;
    for (size_t leaf = 1; leaf < n; ++leaf) {
        uint16_t pendant = (uint16_t)1U << leaf;
        size_t found = 0;
        for (size_t edge = 0; edge < edges; ++edge) found += (size_t)(splits[edge] == pendant);
        if (found != 1) return 0;
    }
    size_t root_pendant = 0;
    for (size_t edge = 0; edge < edges; ++edge) root_pendant += (size_t)(splits[edge] == (uint16_t)(universe ^ 1U));
    if (root_pendant != 1) return 0;
    for (size_t i = 0; i < internal_count; ++i) {
        for (size_t j = i + 1; j < internal_count; ++j) {
            uint16_t common = internal[i] & internal[j];
            if (common != 0 && common != internal[i] && common != internal[j]) return 0;
        }
    }
    return 1;
}

static void sort_state(uint16_t *state, size_t count)
{
    for (size_t i = 1; i < count; ++i) {
        uint16_t value = state[i];
        size_t j = i;
        while (j > 0 && state[j - 1] > value) { state[j] = state[j - 1]; --j; }
        state[j] = value;
    }
}

static int same_state(const uint16_t *left, const uint16_t *right, size_t edges)
{
    for (size_t i = 0; i < edges; ++i) if (left[i] != right[i]) return 0;
    return 1;
}

static uint16_t (*enumerate_states(size_t leaves,
                                    uint16_t states_a[MAX_STATES][MAX_EDGES],
                                    uint16_t states_b[MAX_STATES][MAX_EDGES],
                                    size_t *state_count))[MAX_EDGES]
{
    uint16_t (*current)[MAX_EDGES] = states_a;
    uint16_t (*next)[MAX_EDGES] = states_b;
    current[0][0] = 2; current[0][1] = 4; current[0][2] = 6;
    *state_count = 1;
    size_t old_edges = 3;
    for (size_t size = 4; size <= leaves; ++size) {
        size_t new_edges = old_edges + 2;
        uint16_t new_bit = (uint16_t)1U << (size - 1);
        size_t next_count = 0;
        for (size_t state_index = 0; state_index < *state_count; ++state_index) {
            for (size_t selected_index = 0; selected_index < old_edges; ++selected_index) {
                uint16_t selected = current[state_index][selected_index];
                uint16_t candidate[MAX_EDGES] = {0};
                size_t candidate_count = 0;
                for (size_t edge = 0; edge < old_edges; ++edge) {
                    uint16_t split = current[state_index][edge];
                    if (split == selected) {
                        candidate[candidate_count++] = split;
                        candidate[candidate_count++] = (uint16_t)(split | new_bit);
                    } else if ((selected & split) == selected) {
                        candidate[candidate_count++] = (uint16_t)(split | new_bit);
                    } else {
                        candidate[candidate_count++] = split;
                    }
                }
                candidate[candidate_count++] = new_bit;
                sort_state(candidate, candidate_count);
                size_t found = 0;
                while (found < next_count && !same_state(next[found], candidate, new_edges)) ++found;
                if (found == next_count) {
                    if (next_count >= MAX_STATES) return NULL;
                    for (size_t edge = 0; edge < new_edges; ++edge) next[next_count][edge] = candidate[edge];
                    ++next_count;
                }
            }
        }
        uint16_t (*swap)[MAX_EDGES] = current;
        current = next;
        next = swap;
        *state_count = next_count;
        old_edges = new_edges;
    }
    return current;
}

int64_t nni_phylogeny_distance(const int64_t *input, size_t length,
                               uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 7 || length > MAX_INPUT) return -1;
    int64_t leaf_value = input[0];
    if (leaf_value < 3 || leaf_value > MAX_LEAVES) return -1;
    size_t leaves = (size_t)leaf_value;
    size_t edges = 2 * leaves - 3;
    if (length != 1 + 2 * edges || !valid_tree(input, 1, leaves, edges)
        || !valid_tree(input, 1 + edges, leaves, edges)) return -1;

    uint16_t states_a[MAX_STATES][MAX_EDGES] = {{0}};
    uint16_t states_b[MAX_STATES][MAX_EDGES] = {{0}};
    size_t state_count = 0;
    uint16_t (*states)[MAX_EDGES] = enumerate_states(leaves, states_a, states_b, &state_count);
    if (states == NULL) return -1;
    uint16_t start[MAX_EDGES] = {0}, goal[MAX_EDGES] = {0};
    for (size_t i = 0; i < edges; ++i) {
        start[i] = (uint16_t)input[1 + i];
        goal[i] = (uint16_t)input[1 + edges + i];
    }
    sort_state(start, edges); sort_state(goal, edges);
    size_t start_index = state_count, goal_index = state_count;
    for (size_t i = 0; i < state_count; ++i) {
        if (same_state(states[i], start, edges)) start_index = i;
        if (same_state(states[i], goal, edges)) goal_index = i;
    }
    if (start_index == state_count || goal_index == state_count) return -1;

    uint16_t neighbors[MAX_STATES][MAX_DEGREE] = {{0}};
    uint8_t degree[MAX_STATES] = {0};
    for (size_t left = 0; left < state_count; ++left) {
        for (size_t right = left + 1; right < state_count; ++right) {
            size_t common = 0;
            for (size_t i = 0; i < edges; ++i) {
                size_t left_size = bit_count(states[left][i], leaves);
                if (left_size < 2 || left_size > leaves - 2) continue;
                for (size_t j = 0; j < edges; ++j) {
                    size_t right_size = bit_count(states[right][j], leaves);
                    if (right_size >= 2 && right_size <= leaves - 2 && states[left][i] == states[right][j]) { ++common; break; }
                }
            }
            if (common + leaves == edges - 1) {
                if (degree[left] >= MAX_DEGREE || degree[right] >= MAX_DEGREE) return -1;
                neighbors[left][degree[left]++] = (uint16_t)right;
                neighbors[right][degree[right]++] = (uint16_t)left;
            }
        }
    }
    int16_t distance[MAX_STATES];
    uint16_t queue[MAX_STATES];
    for (size_t i = 0; i < state_count; ++i) distance[i] = -1;
    size_t head = 0, tail = 0;
    distance[start_index] = 0;
    queue[tail++] = (uint16_t)start_index;
    while (head < tail) {
        size_t current = queue[head++];
        if (current == goal_index) break;
        for (size_t i = 0; i < degree[current]; ++i) {
            size_t next = neighbors[current][i];
            if (distance[next] < 0) {
                distance[next] = (int16_t)(distance[current] + 1);
                queue[tail++] = (uint16_t)next;
            }
        }
    }
    if (distance[goal_index] < 0) return -1;
    if (output == NULL || capacity < 8) return -2;
    uint8_t staged[8] = {0};
    store_i64_le(staged, 0, distance[goal_index]);
    for (size_t byte = 0; byte < 8; ++byte) output[byte] = staged[byte];
    return 8;
}
