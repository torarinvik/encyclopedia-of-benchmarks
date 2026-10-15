// Source-faithful port of TheAlgorithms/Go graph.Topological.
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t topological(const std::int64_t *values, std::size_t length,
                                    std::uint8_t *output, std::size_t output_capacity)
{
    if (values == nullptr || length < 1 || length > 66 || (length - 1) % 2 != 0) return -2;
    if (values[0] < 0 || values[0] > 64) return -2;
    const std::size_t vertices = static_cast<std::size_t>(values[0]);
    const std::size_t edge_count = (length - 1) / 2;
    std::uint8_t dependencies[64] = {};
    std::uint64_t adjacency[64] = {};
    std::uint8_t answer[96];

    for (std::size_t edge = 0; edge < edge_count; ++edge) {
        const std::int64_t origin_value = values[1 + 2 * edge];
        const std::int64_t destination_value = values[2 + 2 * edge];
        if (origin_value < 0 || destination_value < 0 ||
            static_cast<std::uint64_t>(origin_value) >= vertices ||
            static_cast<std::uint64_t>(destination_value) >= vertices) return -2;
        const std::size_t origin = static_cast<std::size_t>(origin_value);
        const std::size_t destination = static_cast<std::size_t>(destination_value);
        ++dependencies[destination];
        adjacency[origin] |= UINT64_C(1) << destination;
    }

    std::size_t answer_count = 0;
    for (std::size_t root = 0; root < vertices; ++root) {
        if (dependencies[root] != 0) continue;
        std::size_t stack[64];
        std::size_t top = 0;
        stack[top++] = root;
        while (top > 0) {
            const std::size_t origin = stack[--top];
            answer[answer_count++] = static_cast<std::uint8_t>(origin);
            for (std::size_t destination = 0; destination < vertices; ++destination) {
                const std::uint64_t edge_mask = UINT64_C(1) << destination;
                if ((adjacency[origin] & edge_mask) != 0) {
                    bool in_stack = false;
                    for (std::size_t index = 0; index < top; ++index) {
                        if (stack[index] == destination) {
                            in_stack = true;
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

    if (output_capacity < answer_count || (answer_count != 0 && output == nullptr)) return -2;
    for (std::size_t index = 0; index < answer_count; ++index) output[index] = answer[index];
    return static_cast<std::int64_t>(answer_count);
}
