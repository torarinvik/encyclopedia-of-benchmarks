#include <stddef.h>
#include <stdint.h>

#define MAX_TEXT_LENGTH 64u
#define MAX_PATTERN_LENGTH 16u
#define MAX_VALID_INPUT_LENGTH (2u + MAX_TEXT_LENGTH + MAX_PATTERN_LENGTH)
#define MAX_PARSEABLE_INPUT_LENGTH (MAX_VALID_INPUT_LENGTH + 1u)
#define MAX_TRIE_NODES (1u + MAX_TEXT_LENGTH * (MAX_TEXT_LENGTH + 1u) / 2u)
#define MAX_TRIE_EDGES (MAX_TRIE_NODES - 1u)

int64_t suffix_trie_search(const int64_t *input, size_t input_length)
{
    if (input == NULL || input_length < 2u ||
        input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;

    if (input[0] < 0 || input[0] > (int64_t)MAX_TEXT_LENGTH ||
        input[1] < 0 || input[1] > (int64_t)MAX_PATTERN_LENGTH) return -1;
    const size_t text_length = (size_t)input[0];
    const size_t pattern_length = (size_t)input[1];
    if (input_length != 2u + text_length + pattern_length) return -1;

    const size_t text_start = 2u;
    const size_t pattern_start = text_start + text_length;
    for (size_t i = 0u; i < text_length + pattern_length; ++i) {
        if (input[text_start + i] < 0 || input[text_start + i] > 127) return -1;
    }

    /* Edge 0 means absent; root node 0 is never stored as a child target. */
    size_t first_edge[MAX_TRIE_NODES] = {0u};
    size_t edge_target[MAX_TRIE_EDGES + 1u] = {0u};
    size_t next_edge[MAX_TRIE_EDGES + 1u] = {0u};
    uint8_t edge_code[MAX_TRIE_EDGES + 1u] = {0u};
    size_t node_count = 1u;
    size_t edge_count = 0u;

    /* Insert text[start:] for each start position, sharing trie prefixes. */
    for (size_t start = 0u; start < text_length; ++start) {
        size_t node = 0u;
        for (size_t position = start; position < text_length; ++position) {
            const uint8_t code = (uint8_t)input[text_start + position];
            size_t edge = first_edge[node];
            while (edge != 0u && edge_code[edge] != code) edge = next_edge[edge];
            if (edge == 0u) {
                if (node_count >= MAX_TRIE_NODES || edge_count >= MAX_TRIE_EDGES) return -1;
                const size_t child = node_count++;
                edge = ++edge_count;
                edge_code[edge] = code;
                edge_target[edge] = child;
                next_edge[edge] = first_edge[node];
                first_edge[node] = edge;
            }
            node = edge_target[edge];
        }
    }

    size_t node = 0u;
    for (size_t i = 0u; i < pattern_length; ++i) {
        const uint8_t code = (uint8_t)input[pattern_start + i];
        size_t edge = first_edge[node];
        while (edge != 0u && edge_code[edge] != code) edge = next_edge[edge];
        if (edge == 0u) return 0;
        node = edge_target[edge];
    }
    return 1;
}
