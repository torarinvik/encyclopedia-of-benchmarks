#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_VERTEX_COUNT 8
#define MAX_EDGE_COUNT 32
#define MAX_INPUT_LENGTH (2 + 2 * MAX_EDGE_COUNT)

int64_t incremental_scc(const int64_t *input, size_t length)
{
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > MAX_VERTEX_COUNT || input[1] < 0 || input[1] > MAX_EDGE_COUNT)
        return -1;
    const size_t vertex_count = (size_t)input[0];
    const size_t edge_count = (size_t)input[1];
    if (length != 2 + 2 * edge_count) return -1;

    size_t from[MAX_EDGE_COUNT], to[MAX_EDGE_COUNT];
    for (size_t edge = 0; edge < edge_count; ++edge) {
        const int64_t source = input[2 + 2 * edge], destination = input[3 + 2 * edge];
        if (source < 0 || destination < 0 || source >= (int64_t)vertex_count ||
            destination >= (int64_t)vertex_count) return -1;
        from[edge] = (size_t)source;
        to[edge] = (size_t)destination;
    }

    bool reachable[MAX_VERTEX_COUNT][MAX_VERTEX_COUNT] = {{false}};
    for (size_t vertex = 0; vertex < vertex_count; ++vertex) reachable[vertex][vertex] = true;
    int64_t checksum = 0;
    for (size_t edge = 0; edge < edge_count; ++edge) {
        bool predecessor[MAX_VERTEX_COUNT], successor[MAX_VERTEX_COUNT];
        const size_t source = from[edge], destination = to[edge];
        for (size_t vertex = 0; vertex < vertex_count; ++vertex) {
            predecessor[vertex] = reachable[vertex][source];
            successor[vertex] = reachable[destination][vertex];
        }
        for (size_t first = 0; first < vertex_count; ++first)
            for (size_t second = 0; second < vertex_count; ++second)
                if (predecessor[first] && successor[second]) reachable[first][second] = true;

        bool assigned[MAX_VERTEX_COUNT] = {false};
        size_t component_count = 0;
        for (size_t first = 0; first < vertex_count; ++first) {
            if (assigned[first]) continue;
            ++component_count;
            for (size_t vertex = first; vertex < vertex_count; ++vertex)
                if (reachable[first][vertex] && reachable[vertex][first]) assigned[vertex] = true;
        }
        checksum += (int64_t)(edge + 1) * (int64_t)component_count;
    }
    return checksum;
}
