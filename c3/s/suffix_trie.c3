module suffix_trie;

const usz MAX_TEXT_LENGTH = 64;
const usz MAX_PATTERN_LENGTH = 16;
const usz MAX_VALID_INPUT_LENGTH = 82;
const usz MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1;
const usz MAX_TRIE_NODES = 1 + MAX_TEXT_LENGTH * (MAX_TEXT_LENGTH + 1) / 2;
const usz MAX_TRIE_EDGES = MAX_TRIE_NODES - 1;

fn long suffix_trie_search(long* input, usz input_length)
    @export("suffix_trie_search")
{
    if (input == null || input_length < 2 ||
        input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;

    if (input[0] < 0 || input[0] > (long)MAX_TEXT_LENGTH ||
        input[1] < 0 || input[1] > (long)MAX_PATTERN_LENGTH) return -1;
    usz text_length = (usz)input[0];
    usz pattern_length = (usz)input[1];
    if (input_length != 2 + text_length + pattern_length) return -1;

    usz text_start = 2;
    usz pattern_start = text_start + text_length;
    for (usz i = 0; i < text_length + pattern_length; i++) {
        long code = input[text_start + i];
        if (code < 0 || code > 127) return -1;
    }

    /* Edge 0 means absent; node 0 is the root. */
    usz[MAX_TRIE_NODES] first_edge = zeroed;
    usz[MAX_TRIE_EDGES + 1] edge_target = zeroed;
    usz[MAX_TRIE_EDGES + 1] next_edge = zeroed;
    char[MAX_TRIE_EDGES + 1] edge_code = zeroed;
    usz node_count = 1;
    usz edge_count = 0;

    for (usz start = 0; start < text_length; start++) {
        usz node = 0;
        for (usz position = start; position < text_length; position++) {
            char code = (char)input[text_start + position];
            usz edge = first_edge[node];
            while (edge != 0 && edge_code[edge] != code) edge = next_edge[edge];
            if (edge == 0) {
                if (node_count >= MAX_TRIE_NODES || edge_count >= MAX_TRIE_EDGES) return -1;
                usz child = node_count++;
                edge = ++edge_count;
                edge_code[edge] = code;
                edge_target[edge] = child;
                next_edge[edge] = first_edge[node];
                first_edge[node] = edge;
            }
            node = edge_target[edge];
        }
    }

    usz node = 0;
    for (usz i = 0; i < pattern_length; i++) {
        char code = (char)input[pattern_start + i];
        usz edge = first_edge[node];
        while (edge != 0 && edge_code[edge] != code) edge = next_edge[edge];
        if (edge == 0) return 0;
        node = edge_target[edge];
    }
    return 1;
}
