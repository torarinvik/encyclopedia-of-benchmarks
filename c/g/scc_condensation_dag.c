#include <stddef.h>
#include <stdint.h>

#define MAX_N 8
#define MAX_M 28
#define MAX_INPUT_LENGTH 58
#define MAX_OUTPUT_BYTES 17

int64_t scc_condensation_dag(const int64_t *input, size_t length,
                             uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t n_value = input[0], m_value = input[1];
    if (n_value < 0 || n_value > MAX_N || m_value < 0 || m_value > MAX_M) return -1;
    const size_t n = (size_t)n_value, m = (size_t)m_value;
    if (length != 2 + 2 * m) return -1;
    uint16_t adjacency[MAX_N] = {0}, reverse[MAX_N] = {0};
    for (size_t i = 0; i < m; ++i) {
        const int64_t source = input[2 + 2 * i], target = input[3 + 2 * i];
        if (source < 0 || source >= n_value || target < 0 || target >= n_value) return -1;
        adjacency[(size_t)source] |= (uint16_t)(1u << (unsigned)target);
        reverse[(size_t)target] |= (uint16_t)(1u << (unsigned)source);
    }

    uint8_t visited[MAX_N] = {0}, order[MAX_N] = {0};
    uint8_t stack_vertex[MAX_N] = {0}, stack_next[MAX_N] = {0};
    size_t order_count = 0;
    for (size_t start = 0; start < n; ++start) {
        if (visited[start]) continue;
        size_t stack_size = 1;
        stack_vertex[0] = (uint8_t)start;
        stack_next[0] = 0;
        visited[start] = 1;
        while (stack_size > 0) {
            const size_t frame = stack_size - 1;
            const size_t vertex = stack_vertex[frame];
            size_t candidate = stack_next[frame];
            while (candidate < n && (adjacency[vertex] & (uint16_t)(1u << candidate)) == 0) ++candidate;
            if (candidate < n) {
                stack_next[frame] = (uint8_t)(candidate + 1);
                if (!visited[candidate]) {
                    visited[candidate] = 1;
                    stack_vertex[stack_size] = (uint8_t)candidate;
                    stack_next[stack_size] = 0;
                    ++stack_size;
                }
            } else {
                order[order_count++] = (uint8_t)vertex;
                --stack_size;
            }
        }
    }

    int8_t raw_component[MAX_N];
    for (size_t i = 0; i < n; ++i) raw_component[i] = -1;
    for (size_t i = 0; i < n; ++i) visited[i] = 0;
    size_t component_count = 0;
    while (order_count > 0) {
        const size_t start = order[--order_count];
        if (visited[start]) continue;
        size_t stack_size = 1;
        stack_vertex[0] = (uint8_t)start;
        visited[start] = 1;
        raw_component[start] = (int8_t)component_count;
        while (stack_size > 0) {
            const size_t vertex = stack_vertex[--stack_size];
            for (size_t next = 0; next < n; ++next) {
                if ((reverse[vertex] & (uint16_t)(1u << next)) != 0 && !visited[next]) {
                    visited[next] = 1;
                    raw_component[next] = (int8_t)component_count;
                    stack_vertex[stack_size++] = (uint8_t)next;
                }
            }
        }
        ++component_count;
    }

    uint8_t minimum[MAX_N], raw_order[MAX_N], canonical[MAX_N], labels[MAX_N], row_mask[MAX_N] = {0};
    for (size_t component = 0; component < component_count; ++component) {
        minimum[component] = (uint8_t)n;
        raw_order[component] = (uint8_t)component;
    }
    for (size_t vertex = 0; vertex < n; ++vertex) {
        const size_t component = (size_t)raw_component[vertex];
        if (vertex < minimum[component]) minimum[component] = (uint8_t)vertex;
    }
    for (size_t i = 1; i < component_count; ++i) {
        const uint8_t key = raw_order[i];
        size_t j = i;
        while (j > 0 && minimum[raw_order[j - 1]] > minimum[key]) {
            raw_order[j] = raw_order[j - 1];
            --j;
        }
        raw_order[j] = key;
    }
    for (size_t i = 0; i < component_count; ++i) canonical[raw_order[i]] = (uint8_t)i;
    for (size_t vertex = 0; vertex < n; ++vertex) labels[vertex] = canonical[(size_t)raw_component[vertex]];
    for (size_t source = 0; source < n; ++source) {
        for (size_t target = 0; target < n; ++target) {
            if ((adjacency[source] & (uint16_t)(1u << target)) == 0) continue;
            const uint8_t left = labels[source], right = labels[target];
            if (left != right) row_mask[left] |= (uint8_t)(1u << right);
        }
    }

    uint8_t staged[MAX_OUTPUT_BYTES];
    staged[0] = (uint8_t)component_count;
    for (size_t vertex = 0; vertex < n; ++vertex) staged[1 + vertex] = labels[vertex];
    for (size_t component = 0; component < component_count; ++component)
        staged[1 + n + component] = row_mask[component];
    const size_t output_size = 1 + n + component_count;
    if (output == NULL || capacity < output_size) return -2;
    for (size_t i = 0; i < output_size; ++i) output[i] = staged[i];
    return (int64_t)output_size;
}
