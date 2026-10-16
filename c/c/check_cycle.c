/* Detect directed cycles with iterative three-color depth-first search. */
#include <stddef.h>
#include <stdint.h>

#define MAX_VERTICES 32
#define MAX_EDGES 256
#define MAX_MATRIX (MAX_VERTICES * MAX_VERTICES)

int64_t check_cycle(const int64_t *input, size_t length)
{
    if (input == NULL || length < 2 || input[0] < 0 || input[0] > MAX_VERTICES ||
        input[1] < 0 || input[1] > MAX_EDGES) return -1;
    const size_t vertices = (size_t)input[0];
    const size_t edges = (size_t)input[1];
    if (length != 2 + 2 * edges) return -1;

    uint8_t adjacency[MAX_MATRIX] = {0};
    for (size_t edge = 0; edge < edges; ++edge) {
        const int64_t origin = input[2 + 2 * edge];
        const int64_t destination = input[3 + 2 * edge];
        if (origin < 0 || (uint64_t)origin >= vertices || destination < 0 ||
            (uint64_t)destination >= vertices) return -1;
        adjacency[(size_t)origin * MAX_VERTICES + (size_t)destination] = 1;
    }

    uint8_t color[MAX_VERTICES] = {0};
    size_t stack[MAX_VERTICES];
    size_t next_neighbor[MAX_VERTICES];
    for (size_t start = 0; start < vertices; ++start) {
        if (color[start] != 0) continue;
        size_t top = 1;
        stack[0] = start;
        next_neighbor[0] = 0;
        color[start] = 1;
        while (top != 0) {
            const size_t frame = top - 1;
            const size_t current = stack[frame];
            while (next_neighbor[frame] < vertices &&
                   !adjacency[current * MAX_VERTICES + next_neighbor[frame]]) {
                ++next_neighbor[frame];
            }
            if (next_neighbor[frame] == vertices) {
                color[current] = 2;
                --top;
                continue;
            }
            const size_t neighbor = next_neighbor[frame]++;
            if (color[neighbor] == 1) return 1;
            if (color[neighbor] == 0) {
                color[neighbor] = 1;
                stack[top] = neighbor;
                next_neighbor[top] = 0;
                ++top;
            }
        }
    }
    return 0;
}
