#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_SIDE 8
#define MAX_VERTICES (2 * MAX_SIDE)
#define MAX_PARSEABLE_INPUT_LENGTH (MAX_SIDE + 3)

static bool augment_left(int left, int left_count, int right_count,
                         const uint16_t rows[MAX_SIDE], const int8_t states[MAX_VERTICES],
                         int8_t match_right[MAX_SIDE], bool seen[MAX_SIDE]) {
    for (int right = 0; right < right_count; ++right) {
        if ((rows[left] & (uint16_t)(1u << right)) == 0 || seen[right]) continue;
        if (states != NULL && states[left_count + right] != -1) continue;
        seen[right] = true;
        const int owner = match_right[right];
        if (owner == -1 || augment_left(owner, left_count, right_count, rows,
                                         states, match_right, seen)) {
            match_right[right] = (int8_t)left;
            return true;
        }
    }
    return false;
}

static int maximum_matching(int left_count, int right_count,
                            const uint16_t rows[MAX_SIDE],
                            const int8_t states[MAX_VERTICES],
                            int8_t match_right[MAX_SIDE]) {
    for (int right = 0; right < right_count; ++right) match_right[right] = -1;
    int size = 0;
    for (int left = 0; left < left_count; ++left) {
        if (states != NULL && states[left] != -1) continue;
        bool seen[MAX_SIDE] = {false};
        if (augment_left(left, left_count, right_count, rows, states,
                         match_right, seen)) ++size;
    }
    return size;
}

static int bit_count(uint32_t value) {
    int count = 0;
    while (value != 0) { count += (int)(value & 1u); value >>= 1; }
    return count;
}

static uint32_t alternating_cover(int left_count, int right_count,
                                  const uint16_t rows[MAX_SIDE],
                                  const int8_t match_right[MAX_SIDE]) {
    bool matched_left[MAX_SIDE] = {false};
    bool reachable_left[MAX_SIDE] = {false};
    bool reachable_right[MAX_SIDE] = {false};
    int queue[MAX_SIDE];
    int head = 0, tail = 0;
    for (int right = 0; right < right_count; ++right)
        if (match_right[right] >= 0) matched_left[(int)match_right[right]] = true;
    for (int left = 0; left < left_count; ++left) {
        if (!matched_left[left]) { reachable_left[left] = true; queue[tail++] = left; }
    }
    while (head < tail) {
        const int left = queue[head++];
        for (int right = 0; right < right_count; ++right) {
            if ((rows[left] & (uint16_t)(1u << right)) == 0 || reachable_right[right]
                    || match_right[right] < 0) continue;
            reachable_right[right] = true;
            const int owner = (int)match_right[right];
            if (!reachable_left[owner]) {
                reachable_left[owner] = true;
                queue[tail++] = owner;
            }
        }
    }
    uint32_t result = 0;
    for (int left = 0; left < left_count; ++left)
        if (!reachable_left[left]) result |= 1u << left;
    for (int right = 0; right < right_count; ++right)
        if (reachable_right[right]) result |= 1u << (left_count + right);
    return result;
}

static int minimum_completion_size(int left_count, int right_count,
                                   const uint16_t rows[MAX_SIDE],
                                   const int8_t input_states[MAX_VERTICES]) {
    int8_t states[MAX_VERTICES];
    const int total = left_count + right_count;
    for (int i = 0; i < total; ++i) states[i] = input_states[i];
    bool changed;
    do {
        changed = false;
        for (int left = 0; left < left_count; ++left) {
            for (int right = 0; right < right_count; ++right) {
                if ((rows[left] & (uint16_t)(1u << right)) == 0) continue;
                const int right_vertex = left_count + right;
                if (states[left] == 0 && states[right_vertex] == 0) return -1;
                if (states[left] == 0 && states[right_vertex] == -1) {
                    states[right_vertex] = 1;
                    changed = true;
                } else if (states[right_vertex] == 0 && states[left] == -1) {
                    states[left] = 1;
                    changed = true;
                }
            }
        }
    } while (changed);

    int forced_in = 0;
    for (int i = 0; i < total; ++i) if (states[i] == 1) ++forced_in;
    int8_t residual_match[MAX_SIDE];
    return forced_in + maximum_matching(left_count, right_count, rows, states, residual_match);
}

static uint32_t canonical_cover(int left_count, int right_count,
                                const uint16_t rows[MAX_SIDE], int optimum) {
    int8_t states[MAX_VERTICES];
    const int total = left_count + right_count;
    for (int i = 0; i < total; ++i) states[i] = -1;
    for (int vertex = 0; vertex < total; ++vertex) {
        states[vertex] = 0;
        if (minimum_completion_size(left_count, right_count, rows, states) != optimum)
            states[vertex] = 1;
    }
    uint32_t result = 0;
    for (int vertex = 0; vertex < total; ++vertex)
        if (states[vertex] == 1) result |= 1u << vertex;
    return result;
}

int64_t bipartite_minimum_vertex_cover(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const int64_t left_value = input[0], right_value = input[1];
    if (left_value < 0 || left_value > MAX_SIDE || right_value < 0 || right_value > MAX_SIDE)
        return -1;
    const int left_count = (int)left_value, right_count = (int)right_value;
    if (length != (size_t)(left_count + 2)) return -1;
    const uint16_t right_domain = (uint16_t)((1u << right_count) - 1u);
    uint16_t rows[MAX_SIDE] = {0};
    for (int left = 0; left < left_count; ++left) {
        const int64_t row = input[2 + left];
        if (row < 0 || ((uint64_t)row & ~(uint64_t)right_domain) != 0) return -1;
        rows[left] = (uint16_t)row;
    }

    int8_t match_right[MAX_SIDE];
    const int matching_size = maximum_matching(left_count, right_count, rows, NULL, match_right);
    const uint32_t seed = alternating_cover(left_count, right_count, rows, match_right);
    const int optimum = bit_count(seed);
    if (optimum != matching_size) return -1;
    return (int64_t)canonical_cover(left_count, right_count, rows, optimum);
}
