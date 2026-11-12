#include <stddef.h>
#include <stdint.h>

#define MAX_N 48
#define MAX_NODES (2 * MAX_N - 1)
#define GRID (MAX_N * MAX_N)

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & 255u);
        bits >>= 8;
    }
}

static int intervals_overlap(int left_a, int right_a, int left_b, int right_b) {
    return (left_a < left_b && left_b <= right_a && right_a < right_b) ||
           (left_b < left_a && left_a <= right_b && right_b < right_a);
}

int64_t common_interval_decomposition_tree(const int64_t *input, size_t length,
                                            uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > 1 + MAX_N) return -1;
    if (input[0] < 1 || input[0] > MAX_N) return -1;
    const size_t n = (size_t)input[0];
    if (length != n + 1) return -1;

    uint8_t seen[MAX_N] = {0};
    for (size_t i = 0; i < n; ++i) {
        const int64_t value = input[i + 1];
        if (value < 0 || value >= (int64_t)n || seen[value]) return -1;
        seen[value] = 1;
    }

    uint8_t connected[GRID] = {0};
    uint8_t strong[GRID] = {0};
    for (size_t left = 0; left < n; ++left) {
        int64_t minimum = (int64_t)n;
        int64_t maximum = -1;
        for (size_t right = left; right < n; ++right) {
            const int64_t value = input[right + 1];
            if (value < minimum) minimum = value;
            if (value > maximum) maximum = value;
            const size_t slot = left * MAX_N + right;
            if (maximum - minimum == (int64_t)(right - left)) {
                connected[slot] = 1;
                strong[slot] = 1;
            }
        }
    }

    for (size_t left_a = 0; left_a < n; ++left_a) {
        for (size_t right_a = left_a; right_a < n; ++right_a) {
            const size_t slot_a = left_a * MAX_N + right_a;
            if (!connected[slot_a]) continue;
            for (size_t left_b = 0; left_b < n; ++left_b) {
                for (size_t right_b = left_b; right_b < n; ++right_b) {
                    const size_t slot_b = left_b * MAX_N + right_b;
                    if (slot_b <= slot_a || !connected[slot_b]) continue;
                    if (intervals_overlap((int)left_a, (int)right_a,
                                         (int)left_b, (int)right_b)) {
                        strong[slot_a] = 0;
                        strong[slot_b] = 0;
                    }
                }
            }
        }
    }

    int node_left[MAX_NODES];
    int node_right[MAX_NODES];
    int parent[MAX_NODES];
    int node_type[MAX_NODES];
    size_t node_count = 0;
    for (size_t span = n; span > 0; --span) {
        for (size_t left = 0; left + span <= n; ++left) {
            const size_t right = left + span - 1;
            if (!strong[left * MAX_N + right]) continue;
            node_left[node_count] = (int)left;
            node_right[node_count] = (int)right;
            ++node_count;
        }
    }
    if (node_count == 0 || node_count > MAX_NODES) return -1;

    for (size_t node = 0; node < node_count; ++node) {
        const int span = node_right[node] - node_left[node] + 1;
        int best_span = (int)n + 1;
        parent[node] = -1;
        for (size_t candidate = 0; candidate < node_count; ++candidate) {
            const int candidate_span = node_right[candidate] - node_left[candidate] + 1;
            if (candidate_span > span && candidate_span < best_span &&
                node_left[candidate] <= node_left[node] &&
                node_right[node] <= node_right[candidate]) {
                parent[node] = (int)candidate;
                best_span = candidate_span;
            }
        }
    }

    for (size_t node = 0; node < node_count; ++node) {
        int children[MAX_N];
        size_t child_count = 0;
        for (size_t child = 0; child < node_count; ++child) {
            if (parent[child] != (int)node) continue;
            size_t at = child_count;
            while (at > 0 && node_left[children[at - 1]] > node_left[child]) {
                children[at] = children[at - 1];
                --at;
            }
            children[at] = (int)child;
            ++child_count;
        }

        node_type[node] = 0;
        for (size_t first = 0; first < child_count && node_type[node] == 0; ++first) {
            for (size_t last = first; last < child_count; ++last) {
                const int left = node_left[children[first]];
                const int right = node_right[children[last]];
                int64_t minimum = (int64_t)n;
                int64_t maximum = -1;
                for (int position = left; position <= right; ++position) {
                    const int64_t value = input[(size_t)position + 1];
                    if (value < minimum) minimum = value;
                    if (value > maximum) maximum = value;
                }
                if (maximum - minimum != (int64_t)(right - left)) {
                    node_type[node] = 1;
                    break;
                }
            }
        }
    }

    const size_t output_bytes = (1 + 4 * node_count) * 8;
    if (output == NULL || capacity < output_bytes) return -2;
    store_i64_le(output, 0, (int64_t)node_count);
    for (size_t node = 0; node < node_count; ++node) {
        const size_t offset = 8 + 32 * node;
        store_i64_le(output, offset, (int64_t)parent[node]);
        store_i64_le(output, offset + 8, (int64_t)node_left[node]);
        store_i64_le(output, offset + 16, (int64_t)node_right[node]);
        store_i64_le(output, offset + 24, (int64_t)node_type[node]);
    }
    return (int64_t)output_bytes;
}
