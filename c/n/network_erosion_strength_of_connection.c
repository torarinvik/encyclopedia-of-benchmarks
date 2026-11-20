#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define SOC_MAX_VERTICES 8
#define SOC_MAX_EDGES 56
#define SOC_MAX_PARSEABLE_INPUT 117
#define SOC_OUTPUT_BYTES 16

static int soc_shortest_path(const uint16_t adjacency[SOC_MAX_VERTICES], int n,
                             int source, int target, int path[SOC_MAX_VERTICES]) {
    int distance[SOC_MAX_VERTICES];
    int predecessor[SOC_MAX_VERTICES];
    int queue[SOC_MAX_VERTICES];
    for (int vertex = 0; vertex < n; ++vertex) {
        distance[vertex] = -1;
        predecessor[vertex] = -1;
    }
    int head = 0, tail = 0;
    queue[tail++] = source;
    distance[source] = 0;
    while (head < tail) {
        const int vertex = queue[head++];
        for (int successor = 0; successor < n; ++successor) {
            const uint16_t bit = (uint16_t)(1u << successor);
            if ((adjacency[vertex] & bit) != 0 && distance[successor] == -1) {
                distance[successor] = distance[vertex] + 1;
                predecessor[successor] = vertex;
                queue[tail++] = successor;
            }
        }
    }
    if (distance[target] == -1) return 0;
    int reversed[SOC_MAX_VERTICES];
    int count = 0;
    for (int vertex = target; vertex != -1; vertex = predecessor[vertex]) {
        reversed[count++] = vertex;
        if (vertex == source) break;
    }
    if (reversed[count - 1] != source) return 0;
    for (int index = 0; index < count; ++index)
        path[index] = reversed[count - index - 1];
    return count;
}

static int64_t soc_gcd(int64_t left, int64_t right) {
    while (right != 0) {
        const int64_t remainder = left % right;
        left = right;
        right = remainder;
    }
    return left;
}

static void soc_write_i64(uint8_t *output, int word, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (int byte = 0; byte < 8; ++byte)
        output[word * 8 + byte] = (uint8_t)(bits >> (byte * 8));
}

int64_t network_erosion_strength_of_connection(const int64_t *input, size_t length,
                                                uint8_t *output, size_t capacity) {
    if (input == NULL || length < 4 || length > SOC_MAX_PARSEABLE_INPUT) return -1;
    const int64_t vertex_raw = input[0];
    const int64_t edge_raw = input[1];
    const int64_t source_raw = input[2];
    const int64_t target_raw = input[3];
    if (vertex_raw < 2 || vertex_raw > SOC_MAX_VERTICES || edge_raw < 0 ||
        edge_raw > vertex_raw * (vertex_raw - 1) || source_raw < 0 ||
        source_raw >= vertex_raw || target_raw < 0 || target_raw >= vertex_raw ||
        source_raw == target_raw) return -1;
    const int n = (int)vertex_raw;
    const int edge_count = (int)edge_raw;
    const int source = (int)source_raw;
    const int target = (int)target_raw;
    if (length != (size_t)(4 + 2 * edge_count)) return -1;

    uint16_t adjacency[SOC_MAX_VERTICES] = {0};
    size_t cursor = 4;
    for (int edge = 0; edge < edge_count; ++edge) {
        const int64_t from_raw = input[cursor++];
        const int64_t to_raw = input[cursor++];
        if (from_raw < 0 || from_raw >= n || to_raw < 0 || to_raw >= n ||
            from_raw == to_raw) return -1;
        const int from = (int)from_raw;
        const int to = (int)to_raw;
        const uint16_t bit = (uint16_t)(1u << to);
        if ((adjacency[from] & bit) != 0) return -1;
        adjacency[from] |= bit;
    }

    int distances[SOC_MAX_VERTICES];
    for (int vertex = 0; vertex < n; ++vertex) distances[vertex] = -1;
    int path[SOC_MAX_VERTICES];
    const int first_count = soc_shortest_path(adjacency, n, source, target, path);
    if (first_count != 0) {
        const int initial_length = first_count - 1;
        distances[source] = initial_length;
        distances[target] = initial_length;
        for (;;) {
            const int path_count = soc_shortest_path(adjacency, n, source, target, path);
            if (path_count == 0) break;
            const int path_length = path_count - 1;
            if (path_length == 1) {
                adjacency[source] &= (uint16_t)~(1u << target);
                continue;
            }
            for (int index = 0; index < path_count; ++index) {
                const int vertex = path[index];
                if (distances[vertex] == -1) distances[vertex] = path_length;
            }
            for (int index = 1; index + 1 < path_count; ++index) {
                const int vertex = path[index];
                const uint16_t bit = (uint16_t)(1u << vertex);
                adjacency[vertex] = 0;
                for (int other = 0; other < n; ++other) adjacency[other] &= (uint16_t)~bit;
            }
        }
    }

    int64_t reciprocal_sum_scaled = 0;
    for (int vertex = 0; vertex < n; ++vertex)
        if (distances[vertex] >= 1) reciprocal_sum_scaled += 420 / distances[vertex];
    int64_t numerator = 2 * reciprocal_sum_scaled;
    int64_t denominator = 420 * (n + 2);
    if (numerator == 0) {
        denominator = 1;
    } else {
        const int64_t divisor = soc_gcd(numerator, denominator);
        numerator /= divisor;
        denominator /= divisor;
    }
    if (output == NULL || capacity < SOC_OUTPUT_BYTES) return -2;
    soc_write_i64(output, 0, numerator);
    soc_write_i64(output, 1, denominator);
    return SOC_OUTPUT_BYTES;
}
