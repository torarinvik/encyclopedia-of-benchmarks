#include <stddef.h>
#include <stdint.h>

enum { MAX_VERTICES = 6, MAX_EDGES = 12, MAX_K = 8, MAX_INPUT_LENGTH = 41,
       MAX_FRONTIER = 1 + MAX_K * MAX_EDGES };

static void write_i64(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t k_shortest_walk(const int64_t *values, size_t length,
                        uint8_t *output, size_t output_capacity) {
    if (values == NULL || length < 5 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t n_value = values[0];
    const int64_t m_value = values[1];
    const int64_t source_value = values[2];
    const int64_t target_value = values[3];
    const int64_t k_value = values[4];
    if (n_value < 1 || n_value > MAX_VERTICES || m_value < 0 || m_value > MAX_EDGES ||
        k_value < 1 || k_value > MAX_K || source_value < 0 || source_value >= n_value ||
        target_value < 0 || target_value >= n_value) return -1;
    const size_t n = (size_t)n_value;
    const size_t m = (size_t)m_value;
    const size_t source = (size_t)source_value;
    const size_t target = (size_t)target_value;
    const size_t k = (size_t)k_value;
    if (length != 5 + 3 * m) return -1;

    int64_t head[MAX_VERTICES];
    int64_t edge_to[MAX_EDGES], edge_weight[MAX_EDGES], edge_next[MAX_EDGES];
    for (size_t vertex = 0; vertex < n; ++vertex) head[vertex] = -1;
    for (size_t edge = 0; edge < m; ++edge) {
        const int64_t u = values[5 + 3 * edge];
        const int64_t v = values[6 + 3 * edge];
        const int64_t weight = values[7 + 3 * edge];
        if (u < 0 || u >= n_value || v < 0 || v >= n_value || weight < 0 || weight > 1000)
            return -1;
        edge_to[edge] = v;
        edge_weight[edge] = weight;
        edge_next[edge] = head[(size_t)u];
        head[(size_t)u] = (int64_t)edge;
    }
    if (output == NULL || output_capacity < 8 * k) return -2;

    int64_t queue_distance[MAX_FRONTIER], queue_vertex[MAX_FRONTIER], queue_order[MAX_FRONTIER];
    int64_t expanded[MAX_VERTICES] = {0};
    int64_t answers[MAX_K];
    size_t queue_count = 1;
    int64_t next_order = 1;
    size_t answer_count = 0;
    queue_distance[0] = 0;
    queue_vertex[0] = (int64_t)source;
    queue_order[0] = 0;

    while (queue_count != 0 && answer_count < k) {
        const int64_t distance = queue_distance[0];
        const size_t vertex = (size_t)queue_vertex[0];
        for (size_t slot = 1; slot < queue_count; ++slot) {
            queue_distance[slot - 1] = queue_distance[slot];
            queue_vertex[slot - 1] = queue_vertex[slot];
            queue_order[slot - 1] = queue_order[slot];
        }
        --queue_count;
        if (expanded[vertex] >= (int64_t)k) continue;
        ++expanded[vertex];
        if (vertex == target) {
            answers[answer_count++] = distance;
            if (answer_count == k) break;
        }
        for (int64_t edge = head[vertex]; edge >= 0; edge = edge_next[(size_t)edge]) {
            const int64_t candidate_distance = distance + edge_weight[(size_t)edge];
            const int64_t candidate_vertex = edge_to[(size_t)edge];
            const int64_t candidate_order = next_order++;
            size_t position = queue_count;
            while (position > 0 &&
                   (queue_distance[position - 1] > candidate_distance ||
                    (queue_distance[position - 1] == candidate_distance &&
                     queue_order[position - 1] > candidate_order))) {
                queue_distance[position] = queue_distance[position - 1];
                queue_vertex[position] = queue_vertex[position - 1];
                queue_order[position] = queue_order[position - 1];
                --position;
            }
            queue_distance[position] = candidate_distance;
            queue_vertex[position] = candidate_vertex;
            queue_order[position] = candidate_order;
            ++queue_count;
        }
    }
    while (answer_count < k) answers[answer_count++] = -1;
    for (size_t index = 0; index < k; ++index)
        write_i64(output, 8 * index, answers[index]);
    return (int64_t)(8 * k);
}
