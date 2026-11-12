#include <stddef.h>
#include <stdint.h>

enum { MAX_QUERIES = 32, MAX_TEXT = 32, MAX_NODES = MAX_TEXT + 2,
       ALPHABET = 26 };

typedef struct {
    int length;
    int link;
    int next[ALPHABET];
} EertreeNode;

static int extendable(const EertreeNode *nodes, const int *text, int position,
                      int node) {
    for (;;) {
        int preceding = position - nodes[node].length - 1;
        if (preceding >= 0 && text[preceding] == text[position]) return node;
        node = nodes[node].link;
    }
}

static void summarize(const int *text, int size, int64_t *distinct,
                      int64_t *prefix, int64_t *suffix) {
    EertreeNode nodes[MAX_NODES];
    for (int node = 0; node < MAX_NODES; ++node) {
        nodes[node].length = 0;
        nodes[node].link = 0;
        for (int letter = 0; letter < ALPHABET; ++letter)
            nodes[node].next[letter] = -1;
    }
    nodes[0].length = -1;
    nodes[0].link = 0;
    nodes[1].length = 0;
    nodes[1].link = 0;
    int node_count = 2;
    int last = 1;
    int longest_prefix = 0;

    for (int position = 0; position < size; ++position) {
        int letter = text[position];
        int parent = extendable(nodes, text, position, last);
        int next = nodes[parent].next[letter];
        if (next < 0) {
            next = node_count++;
            nodes[next].length = nodes[parent].length + 2;
            if (nodes[next].length == 1) {
                nodes[next].link = 1;
            } else {
                int suffix_parent = extendable(nodes, text, position,
                                               nodes[parent].link);
                nodes[next].link = nodes[suffix_parent].next[letter];
            }
            nodes[parent].next[letter] = next;
        }
        last = next;
        if (nodes[last].length == position + 1) longest_prefix = position + 1;
    }
    *distinct = node_count - 2;
    *prefix = longest_prefix;
    *suffix = nodes[last].length;
}

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t palindromes_in_deque(const int64_t *input, size_t length,
                             uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || length > 1 + 2 * MAX_QUERIES) return -1;
    int64_t query_value = input[0];
    if (query_value < 1 || query_value > MAX_QUERIES) return -1;
    size_t queries = (size_t)query_value;
    if (length != 1 + 2 * queries) return -1;

    int size = 0;
    for (size_t query = 0; query < queries; ++query) {
        int64_t operation = input[1 + 2 * query];
        int64_t letter = input[2 + 2 * query];
        if (operation == 0 || operation == 1) {
            if (letter < 0 || letter >= ALPHABET) return -1;
            ++size;
        } else if (operation == 2 || operation == 3) {
            if (letter != 0 || size == 0) return -1;
            --size;
        } else {
            return -1;
        }
    }
    if (output == NULL || capacity < 24 * queries) return -2;

    int text[MAX_TEXT];
    size = 0;
    for (size_t query = 0; query < queries; ++query) {
        int operation = (int)input[1 + 2 * query];
        int letter = (int)input[2 + 2 * query];
        if (operation == 0) {
            for (int index = size; index > 0; --index) text[index] = text[index - 1];
            text[0] = letter;
            ++size;
        } else if (operation == 1) {
            text[size++] = letter;
        } else if (operation == 2) {
            for (int index = 1; index < size; ++index) text[index - 1] = text[index];
            --size;
        } else {
            --size;
        }
        int64_t distinct, prefix, suffix;
        summarize(text, size, &distinct, &prefix, &suffix);
        size_t offset = 24 * query;
        store_i64_le(output, offset, distinct);
        store_i64_le(output, offset + 8, prefix);
        store_i64_le(output, offset + 16, suffix);
    }
    return (int64_t)(24 * queries);
}
