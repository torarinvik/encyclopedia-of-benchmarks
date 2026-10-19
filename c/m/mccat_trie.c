#include <stddef.h>
#include <stdint.h>

#define MAX_WORDS 64
#define MAX_WORD_LENGTH 32
#define MAX_INPUT_VALUES (1 + MAX_WORDS * (1 + MAX_WORD_LENGTH))
#define MAX_NODES (MAX_WORDS * MAX_WORD_LENGTH)
#define MAX_OUTPUT_BYTES (MAX_WORDS * (MAX_WORD_LENGTH + 1))

typedef struct {
    uint8_t value;
    uint8_t terminal;
    size_t postfix;
    size_t other_char;
} TrieNode;

static size_t new_node(TrieNode *nodes, size_t *used, uint8_t value) {
    const size_t node = ++*used;
    nodes[node].value = value;
    return node;
}

static size_t new_suffix(TrieNode *nodes, size_t *used, const int64_t *input,
                         size_t start, size_t length) {
    const size_t root = new_node(nodes, used, (uint8_t)input[start]);
    size_t current = root;
    for (size_t i = 1; i < length; ++i) {
        const size_t child = new_node(nodes, used, (uint8_t)input[start + i]);
        nodes[current].postfix = child;
        current = child;
    }
    nodes[current].terminal = 1;
    return root;
}

static void insert_word(TrieNode *nodes, size_t *used, size_t current,
                        const int64_t *input, size_t start,
                        size_t length, size_t offset) {
    if (nodes[current].value == (uint8_t)input[start + offset]) {
        if (offset + 1 == length) {
            nodes[current].terminal = 1;
        } else if (nodes[current].postfix == 0) {
            nodes[current].postfix = new_suffix(nodes, used, input,
                                                start + offset + 1,
                                                length - offset - 1);
        } else {
            insert_word(nodes, used, nodes[current].postfix, input,
                        start, length, offset + 1);
        }
    } else if (nodes[current].other_char == 0) {
        nodes[current].other_char = new_suffix(nodes, used, input,
                                              start + offset,
                                              length - offset);
    } else {
        insert_word(nodes, used, nodes[current].other_char, input,
                    start, length, offset);
    }
}

static void measure_output(const TrieNode *nodes, size_t current,
                           size_t depth, size_t *length) {
    if (current == 0) return;
    if (nodes[current].terminal) *length += depth + 2; /* word bytes + LF */
    measure_output(nodes, nodes[current].postfix, depth + 1, length);
    measure_output(nodes, nodes[current].other_char, depth, length);
}

static void emit_output(const TrieNode *nodes, size_t current, size_t depth,
                        uint8_t *prefix, uint8_t *output, size_t *position) {
    if (current == 0) return;
    prefix[depth] = nodes[current].value;
    if (nodes[current].terminal) {
        for (size_t i = 0; i <= depth; ++i) output[(*position)++] = prefix[i];
        output[(*position)++] = '\n';
    }
    emit_output(nodes, nodes[current].postfix, depth + 1, prefix, output, position);
    emit_output(nodes, nodes[current].other_char, depth, prefix, output, position);
}

int64_t mccat_trie(const int64_t *input, size_t length,
                   uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || length > MAX_INPUT_VALUES) return -1;
    const int64_t word_count_value = input[0];
    if (word_count_value < 0 || word_count_value > MAX_WORDS) return -1;
    const size_t word_count = (size_t)word_count_value;

    size_t starts[MAX_WORDS];
    size_t lengths[MAX_WORDS];
    size_t position = 1;
    for (size_t i = 0; i < word_count; ++i) {
        if (position >= length) return -1;
        const int64_t word_length_value = input[position++];
        if (word_length_value < 1 || word_length_value > MAX_WORD_LENGTH) return -1;
        const size_t word_length = (size_t)word_length_value;
        if (word_length > length - position) return -1;
        starts[i] = position;
        lengths[i] = word_length;
        for (size_t j = 0; j < word_length; ++j) {
            if (input[position + j] < 33 || input[position + j] > 126) return -1;
        }
        position += word_length;
    }
    if (position != length) return -1;

    TrieNode nodes[MAX_NODES + 1] = {{0}};
    size_t used = 0;
    size_t root = 0;
    for (size_t i = 0; i < word_count; ++i) {
        if (root == 0) root = new_suffix(nodes, &used, input, starts[i], lengths[i]);
        else insert_word(nodes, &used, root, input, starts[i], lengths[i], 0);
    }

    size_t output_length = 0;
    measure_output(nodes, root, 0, &output_length);
    if (output_length > MAX_OUTPUT_BYTES) return -1;
    if (output_length != 0 && (output == NULL || capacity < output_length)) return -2;
    if (output_length == 0) return 0;
    uint8_t prefix[MAX_WORD_LENGTH];
    size_t written = 0;
    emit_output(nodes, root, 0, prefix, output, &written);
    return (int64_t)written;
}
