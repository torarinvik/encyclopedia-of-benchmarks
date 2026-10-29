#include <stddef.h>
#include <stdint.h>

enum { MAX_TEXT_LENGTH = 128, MAX_NODES = MAX_TEXT_LENGTH + 2, ALPHABET_SIZE = 26 };

typedef struct {
    int length;
    int suffix_link;
    int next[ALPHABET_SIZE];
} EertreeNode;

static void initialize_node(EertreeNode *node, int length, int suffix_link)
{
    node->length = length;
    node->suffix_link = suffix_link;
    for (int letter = 0; letter < ALPHABET_SIZE; ++letter) node->next[letter] = -1;
}

static int find_extendable(const EertreeNode *nodes, const int64_t *text,
                           size_t position, int start)
{
    int node = start;
    for (;;) {
        int preceding = (int)position - 1 - nodes[node].length;
        if (preceding >= 0 && text[preceding] == text[position]) return node;
        node = nodes[node].suffix_link;
    }
}

int64_t eertree(const int64_t *values, size_t length)
{
    if (values == NULL || length < 1 || length > MAX_TEXT_LENGTH + 1) return -1;
    if (values[0] < 0 || values[0] > MAX_TEXT_LENGTH) return -1;
    size_t text_length = (size_t)values[0];
    if (length != text_length + 1) return -1;
    for (size_t i = 0; i < text_length; ++i)
        if (values[i + 1] < 0 || values[i + 1] >= ALPHABET_SIZE) return -1;

    EertreeNode nodes[MAX_NODES];
    initialize_node(&nodes[0], -1, 0);
    initialize_node(&nodes[1], 0, 0);
    int node_count = 2;
    int longest_suffix = 1;
    int64_t checksum = 0;

    for (size_t position = 0; position < text_length; ++position) {
        const int64_t *text = values + 1;
        int letter = (int)text[position];
        int parent = find_extendable(nodes, text, position, longest_suffix);
        int next = nodes[parent].next[letter];
        if (next < 0) {
            next = node_count++;
            initialize_node(&nodes[next], nodes[parent].length + 2, 0);
            nodes[parent].next[letter] = next;
            if (nodes[next].length == 1) {
                nodes[next].suffix_link = 1;
            } else {
                int suffix_parent = find_extendable(nodes, text, position,
                                                    nodes[parent].suffix_link);
                int suffix = nodes[suffix_parent].next[letter];
                if (suffix < 0) return -1;
                nodes[next].suffix_link = suffix;
            }
        }
        longest_suffix = next;
        checksum += (int64_t)(position + 1) * (node_count - 2);
    }
    return checksum;
}
