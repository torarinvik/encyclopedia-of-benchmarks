module eertree;

const usz MAX_TEXT_LENGTH = 128;
const usz MAX_NODES = MAX_TEXT_LENGTH + 2;
const int ALPHABET_SIZE = 26;

struct Node { int length; int suffix_link; int[26] next; }

fn void initialize_node(Node* nodes, int id, int length, int suffix_link) {
    nodes[id].length = length;
    nodes[id].suffix_link = suffix_link;
    for (int letter = 0; letter < ALPHABET_SIZE; letter++) nodes[id].next[letter] = -1;
}

fn int find_extendable(Node* nodes, long* text, usz position, int start) {
    int node = start;
    while (true) {
        long preceding = (long)position - 1 - nodes[node].length;
        if (preceding >= 0 && text[(usz)preceding] == text[position]) return node;
        node = nodes[node].suffix_link;
    }
}

fn long eertree(long* values, usz length) @export("eertree") {
    if (values == null || length < 1 || length > MAX_TEXT_LENGTH + 1) return -1;
    if (values[0] < 0 || values[0] > (long)MAX_TEXT_LENGTH) return -1;
    usz text_length = (usz)values[0];
    if (length != text_length + 1) return -1;
    for (usz i = 0; i < text_length; i++)
        if (values[i + 1] < 0 || values[i + 1] >= (long)ALPHABET_SIZE) return -1;

    Node[MAX_NODES] nodes;
    initialize_node(&nodes[0], 0, -1, 0);
    initialize_node(&nodes[0], 1, 0, 0);
    int node_count = 2;
    int longest_suffix = 1;
    long checksum = 0;
    long* text = values + 1;

    for (usz position = 0; position < text_length; position++) {
        int letter = (int)text[position];
        int parent = find_extendable(&nodes[0], text, position, longest_suffix);
        int next = nodes[parent].next[letter];
        if (next < 0) {
            next = node_count++;
            initialize_node(&nodes[0], next, nodes[parent].length + 2, 0);
            nodes[parent].next[letter] = next;
            if (nodes[next].length == 1) {
                nodes[next].suffix_link = 1;
            } else {
                int suffix_parent = find_extendable(&nodes[0], text, position,
                                                    nodes[parent].suffix_link);
                int suffix = nodes[suffix_parent].next[letter];
                if (suffix < 0) return -1;
                nodes[next].suffix_link = suffix;
            }
        }
        longest_suffix = next;
        checksum += (long)(position + 1) * (long)(node_count - 2);
    }
    return checksum;
}
