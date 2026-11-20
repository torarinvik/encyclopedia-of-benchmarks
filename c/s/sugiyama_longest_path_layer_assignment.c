#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_N 32
#define MAX_M 128
#define MAX_INPUT 258
#define MAX_OUTPUT 264

static void put_i64_le(uint8_t *output, size_t word, uint64_t value) {
    for (size_t byte = 0; byte < 8; ++byte) {
        output[word * 8 + byte] = (uint8_t)(value >> (8 * byte));
    }
}

int64_t sugiyama_longest_path_layer_assignment(const int64_t *input, size_t length,
                                                uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT + 1) return -1;
    const int64_t n_value = input[0], m_value = input[1];
    if (n_value < 0 || n_value > MAX_N || m_value < 0 || m_value > MAX_M) return -1;
    const size_t n = (size_t)n_value, m = (size_t)m_value;
    if (length != 2 + 2 * m) return -1;

    uint32_t adjacency[MAX_N] = {0};
    for (size_t edge = 0; edge < m; ++edge) {
        const int64_t source = input[2 + 2 * edge], target = input[3 + 2 * edge];
        if (source < 0 || source >= n_value || target < 0 || target >= n_value) return -1;
        const uint32_t bit = UINT32_C(1) << (unsigned)target;
        if ((adjacency[(size_t)source] & bit) != 0) return -1;
        adjacency[(size_t)source] |= bit;
    }

    bool removed[MAX_N] = {false};
    size_t sink_depth[MAX_N] = {0};
    size_t remaining = n, depth = 0;
    while (remaining > 0) {
        bool sinks[MAX_N] = {false};
        size_t sink_count = 0;
        for (size_t vertex = 0; vertex < n; ++vertex) {
            if (removed[vertex]) continue;
            bool has_remaining_successor = false;
            for (size_t target = 0; target < n; ++target) {
                if (!removed[target] &&
                    (adjacency[vertex] & (UINT32_C(1) << target)) != 0) {
                    has_remaining_successor = true;
                    break;
                }
            }
            if (!has_remaining_successor) {
                sinks[vertex] = true;
                ++sink_count;
            }
        }
        if (sink_count == 0) return -1;
        for (size_t vertex = 0; vertex < n; ++vertex) {
            if (sinks[vertex]) {
                removed[vertex] = true;
                sink_depth[vertex] = depth;
            }
        }
        remaining -= sink_count;
        ++depth;
    }

    const size_t layer_count = depth;
    const size_t output_bytes = 8 * (n + 1);
    if (output == NULL || capacity < output_bytes) return -2;
    put_i64_le(output, 0, (uint64_t)layer_count);
    for (size_t vertex = 0; vertex < n; ++vertex) {
        put_i64_le(output, vertex + 1, (uint64_t)(layer_count - 1 - sink_depth[vertex]));
    }
    return (int64_t)output_bytes;
}
