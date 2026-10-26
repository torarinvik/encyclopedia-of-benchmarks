#include <stddef.h>
#include <stdint.h>

#define MAX_VERTICES 8
#define MAX_EDGES 28
#define MAX_INPUT (2 + MAX_VERTICES + 2 * MAX_EDGES)
#define MAX_FIELDS (1 + MAX_VERTICES * (1 + MAX_VERTICES))
#define MAX_OUTPUT_BYTES (8 * MAX_FIELDS)

static void store_i64_le(uint8_t *output, size_t offset, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & 255U);
        bits >>= 8;
    }
}

static int unique_shortest_paths(const uint8_t *adjacency, size_t n)
{
    for (size_t source = 0; source < n; ++source) {
        int distance[MAX_VERTICES];
        uint8_t ways[MAX_VERTICES] = {0};
        size_t queue[MAX_VERTICES];
        for (size_t i = 0; i < n; ++i) distance[i] = -1;
        size_t head = 0, tail = 0;
        distance[source] = 0; ways[source] = 1; queue[tail++] = source;
        while (head < tail) {
            size_t vertex = queue[head++];
            for (size_t neighbor = 0; neighbor < n; ++neighbor) {
                if (adjacency[vertex * MAX_VERTICES + neighbor] == 0) continue;
                if (distance[neighbor] < 0) {
                    distance[neighbor] = distance[vertex] + 1;
                    ways[neighbor] = ways[vertex];
                    queue[tail++] = neighbor;
                } else if (distance[neighbor] == distance[vertex] + 1) {
                    unsigned sum = (unsigned)ways[neighbor] + ways[vertex];
                    ways[neighbor] = (uint8_t)(sum > 1U ? 2U : sum);
                }
            }
        }
        for (size_t vertex = 0; vertex < n; ++vertex) if (ways[vertex] != 1) return 0;
    }
    return 1;
}

int64_t hub_labeling_pruned(const int64_t *input, size_t length,
                            uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 3 || length > MAX_INPUT) return -1;
    int64_t n_value = input[0], m_value = input[1];
    if (n_value < 1 || n_value > MAX_VERTICES || m_value < 0 || m_value > MAX_EDGES) return -1;
    size_t n = (size_t)n_value, m = (size_t)m_value;
    if (length != 2 + n + 2 * m) return -1;
    uint8_t seen_order[MAX_VERTICES] = {0};
    for (size_t i = 0; i < n; ++i) {
        int64_t vertex = input[2 + i];
        if (vertex < 0 || (uint64_t)vertex >= n || seen_order[(size_t)vertex]) return -1;
        seen_order[(size_t)vertex] = 1;
    }
    uint8_t adjacency[MAX_VERTICES * MAX_VERTICES] = {0};
    int64_t previous_left = -1, previous_right = -1;
    for (size_t edge = 0; edge < m; ++edge) {
        int64_t left = input[2 + n + 2 * edge], right = input[3 + n + 2 * edge];
        if (left < 0 || right <= left || (uint64_t)right >= n
            || left < previous_left || (left == previous_left && right <= previous_right)) return -1;
        previous_left = left; previous_right = right;
        adjacency[(size_t)left * MAX_VERTICES + (size_t)right] = 1;
        adjacency[(size_t)right * MAX_VERTICES + (size_t)left] = 1;
    }
    if (!unique_shortest_paths(adjacency, n)) return -1;

    int16_t labels[MAX_VERTICES * MAX_VERTICES];
    for (size_t i = 0; i < MAX_VERTICES * MAX_VERTICES; ++i) labels[i] = -1;
    for (size_t order_index = 0; order_index < n; ++order_index) {
        size_t hub = (size_t)input[2 + order_index];
        int distance[MAX_VERTICES];
        size_t queue[MAX_VERTICES];
        for (size_t i = 0; i < n; ++i) distance[i] = -1;
        size_t head = 0, tail = 0;
        distance[hub] = 0; queue[tail++] = hub;
        while (head < tail) {
            size_t vertex = queue[head++];
            int estimate = 2 * MAX_VERTICES;
            for (size_t common = 0; common < n; ++common) {
                int16_t from_hub = labels[hub * MAX_VERTICES + common];
                int16_t from_vertex = labels[vertex * MAX_VERTICES + common];
                if (from_hub >= 0 && from_vertex >= 0 && from_hub + from_vertex < estimate)
                    estimate = from_hub + from_vertex;
            }
            if (estimate <= distance[vertex]) continue;
            labels[vertex * MAX_VERTICES + hub] = (int16_t)distance[vertex];
            for (size_t neighbor = 0; neighbor < n; ++neighbor) {
                if (adjacency[vertex * MAX_VERTICES + neighbor] != 0 && distance[neighbor] < 0) {
                    distance[neighbor] = distance[vertex] + 1;
                    queue[tail++] = neighbor;
                }
            }
        }
    }
    int64_t fields[MAX_FIELDS] = {0};
    size_t field_count = 0;
    fields[field_count++] = (int64_t)n;
    for (size_t vertex = 0; vertex < n; ++vertex) {
        size_t count_index = field_count++;
        int64_t count = 0;
        for (size_t hub = 0; hub < n; ++hub) {
            int16_t value = labels[vertex * MAX_VERTICES + hub];
            if (value >= 0) {
                fields[field_count++] = (int64_t)hub | ((int64_t)value << 8);
                ++count;
            }
        }
        fields[count_index] = count;
    }
    size_t bytes = field_count * 8;
    if (output == NULL || capacity < bytes) return -2;
    uint8_t staged[MAX_OUTPUT_BYTES] = {0};
    for (size_t i = 0; i < field_count; ++i) store_i64_le(staged, 8 * i, fields[i]);
    for (size_t i = 0; i < bytes; ++i) output[i] = staged[i];
    return (int64_t)bytes;
}
