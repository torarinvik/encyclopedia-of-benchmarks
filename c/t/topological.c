/* Source-faithful port of TheAlgorithms/Go graph.Topological. */
#include <stddef.h>
#include <stdint.h>

int64_t topological(const int64_t *values, size_t length,
                    uint8_t *output, size_t output_capacity)
{
    if (values == NULL || length < 1 || length > 66 || (length - 1) % 2 != 0) return -2;
    if (values[0] < 0 || values[0] > 64) return -2;
    const size_t vertices = (size_t)values[0];
    const size_t edge_count = (length - 1) / 2;
    uint8_t dependencies[64] = {0};
    uint64_t adjacency[64] = {0};
    uint8_t answer[96];

    for (size_t edge = 0; edge < edge_count; ++edge) {
        const int64_t origin_value = values[1 + 2 * edge];
        const int64_t destination_value = values[2 + 2 * edge];
        if (origin_value < 0 || destination_value < 0 ||
            (uint64_t)origin_value >= vertices || (uint64_t)destination_value >= vertices) return -2;
        const size_t origin = (size_t)origin_value;
        const size_t destination = (size_t)destination_value;
        ++dependencies[destination];
        adjacency[origin] |= UINT64_C(1) << destination;
    }

    size_t answer_count = 0;
    for (size_t root = 0; root < vertices; ++root) {
        if (dependencies[root] != 0) continue;
        size_t stack[64];
        size_t top = 0;
        stack[top++] = root;
        while (top > 0) {
            const size_t origin = stack[--top];
            answer[answer_count++] = (uint8_t)origin;
            for (size_t destination = 0; destination < vertices; ++destination) {
                const uint64_t edge_mask = UINT64_C(1) << destination;
                if ((adjacency[origin] & edge_mask) != 0) {
                    int in_stack = 0;
                    for (size_t index = 0; index < top; ++index) {
                        if (stack[index] == destination) {
                            in_stack = 1;
                            break;
                        }
                    }
                    if (!in_stack) stack[top++] = destination;
                }
                adjacency[origin] &= ~edge_mask;
                adjacency[destination] &= ~(UINT64_C(1) << origin);
            }
        }
    }

    if (output_capacity < answer_count || (answer_count != 0 && output == NULL)) return -2;
    for (size_t index = 0; index < answer_count; ++index) output[index] = answer[index];
    return (int64_t)answer_count;
}
