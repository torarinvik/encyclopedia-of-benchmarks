#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_text_length = 64;
constexpr std::size_t max_pattern_length = 16;
constexpr std::size_t max_valid_input_length = 2 + max_text_length + max_pattern_length;
constexpr std::size_t max_parseable_input_length = max_valid_input_length + 1;
constexpr std::size_t max_trie_nodes = 1 + max_text_length * (max_text_length + 1) / 2;
constexpr std::size_t max_trie_edges = max_trie_nodes - 1;
} // namespace

extern "C" std::int64_t suffix_trie_search(const std::int64_t* input,
                                            std::size_t input_length) noexcept
{
    if (input == nullptr || input_length < 2 ||
        input_length > max_parseable_input_length) return -1;
    if (input[0] < 0 || input[0] > static_cast<std::int64_t>(max_text_length) ||
        input[1] < 0 || input[1] > static_cast<std::int64_t>(max_pattern_length)) return -1;

    const std::size_t text_length = static_cast<std::size_t>(input[0]);
    const std::size_t pattern_length = static_cast<std::size_t>(input[1]);
    if (input_length != 2 + text_length + pattern_length) return -1;

    const std::size_t text_start = 2;
    const std::size_t pattern_start = text_start + text_length;
    for (std::size_t i = 0; i < text_length + pattern_length; ++i) {
        const std::int64_t code = input[text_start + i];
        if (code < 0 || code > 127) return -1;
    }

    /* Edge 0 means absent; node 0 is the root. */
    std::size_t first_edge[max_trie_nodes] = {};
    std::size_t edge_target[max_trie_edges + 1] = {};
    std::size_t next_edge[max_trie_edges + 1] = {};
    std::uint8_t edge_code[max_trie_edges + 1] = {};
    std::size_t node_count = 1;
    std::size_t edge_count = 0;

    for (std::size_t start = 0; start < text_length; ++start) {
        std::size_t node = 0;
        for (std::size_t position = start; position < text_length; ++position) {
            const std::uint8_t code = static_cast<std::uint8_t>(input[text_start + position]);
            std::size_t edge = first_edge[node];
            while (edge != 0 && edge_code[edge] != code) edge = next_edge[edge];
            if (edge == 0) {
                if (node_count >= max_trie_nodes || edge_count >= max_trie_edges) return -1;
                const std::size_t child = node_count++;
                edge = ++edge_count;
                edge_code[edge] = code;
                edge_target[edge] = child;
                next_edge[edge] = first_edge[node];
                first_edge[node] = edge;
            }
            node = edge_target[edge];
        }
    }

    std::size_t node = 0;
    for (std::size_t i = 0; i < pattern_length; ++i) {
        const std::uint8_t code = static_cast<std::uint8_t>(input[pattern_start + i]);
        std::size_t edge = first_edge[node];
        while (edge != 0 && edge_code[edge] != code) edge = next_edge[edge];
        if (edge == 0) return 0;
        node = edge_target[edge];
    }
    return 1;
}
