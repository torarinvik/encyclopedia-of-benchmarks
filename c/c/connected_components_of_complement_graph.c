#include <stddef.h>
#include <stdint.h>

#define MAX_N 64
#define MAX_M (MAX_N * (MAX_N - 1) / 2)
#define MAX_INPUT_VALUES (2 + 2 * MAX_M)
#define MAX_OUTPUT_VALUES (1 + 2 * MAX_N)

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t connected_components_of_complement_graph(const int64_t *input, size_t length,
    uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT_VALUES) return -1;
    const int64_t n_value = input[0], m_value = input[1];
    if (n_value < 1 || n_value > MAX_N || m_value < 0 ||
        m_value > n_value * (n_value - 1) / 2) return -1;
    const size_t n = (size_t)n_value, m = (size_t)m_value;
    if (length != 2 + 2 * m) return -1;

    uint64_t graph[MAX_N] = {0};
    for (size_t edge = 0; edge < m; ++edge) {
        const int64_t left_value = input[2 + 2 * edge];
        const int64_t right_value = input[3 + 2 * edge];
        if (left_value < 0 || left_value >= n_value || right_value < 0 ||
            right_value >= n_value || left_value == right_value) return -1;
        const size_t left = (size_t)left_value, right = (size_t)right_value;
        const uint64_t left_bit = UINT64_C(1) << right;
        if ((graph[left] & left_bit) != 0) return -1;
        graph[left] |= left_bit;
        graph[right] |= UINT64_C(1) << left;
    }

    size_t remaining[MAX_N], queue[MAX_N];
    int64_t label[MAX_N];
    for (size_t vertex = 0; vertex < n; ++vertex) {
        remaining[vertex] = vertex;
        label[vertex] = -1;
    }
    size_t remaining_count = n, component_count = 0;
    while (remaining_count > 0) {
        const size_t root = remaining[--remaining_count];
        label[root] = (int64_t)component_count;
        size_t head = 0, tail = 0;
        queue[tail++] = root;
        while (head < tail) {
            const size_t vertex = queue[head++];
            size_t position = 0;
            while (position < remaining_count) {
                const size_t candidate = remaining[position];
                if (((graph[vertex] >> candidate) & 1u) != 0) {
                    ++position;
                } else {
                    remaining[position] = remaining[--remaining_count];
                    label[candidate] = (int64_t)component_count;
                    queue[tail++] = candidate;
                }
            }
        }
        ++component_count;
    }

    int64_t staged[MAX_OUTPUT_VALUES];
    size_t used = 0;
    staged[used++] = (int64_t)component_count;
    uint8_t emitted[MAX_N] = {0};
    for (size_t first = 0; first < n; ++first) {
        const size_t component = (size_t)label[first];
        if (emitted[component]) continue;
        emitted[component] = 1;
        size_t component_size = 0;
        for (size_t vertex = 0; vertex < n; ++vertex)
            if ((size_t)label[vertex] == component) ++component_size;
        staged[used++] = (int64_t)component_size;
        for (size_t vertex = 0; vertex < n; ++vertex)
            if ((size_t)label[vertex] == component) staged[used++] = (int64_t)vertex;
    }

    const size_t required = 8 * used;
    if (output == NULL || capacity < required) return -2;
    for (size_t index = 0; index < used; ++index)
        store_i64_le(output, 8 * index, staged[index]);
    return (int64_t)required;
}
