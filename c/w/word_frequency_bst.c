/* Bounded projection of the pinned ASCII tokenizer and unbalanced BST. */
#include <stddef.h>
#include <stdint.h>

#define MAX_INPUT_BYTES 256
#define MAX_TOKEN_BYTES 45
#define MAX_UNIQUE_WORDS 128
#define MAX_OUTPUT_BYTES 896

typedef struct {
    uint8_t word[MAX_TOKEN_BYTES + 1];
    size_t word_length;
    uint64_t frequency;
    int left;
    int right;
} WordNode;

static int ascii_alpha(uint8_t value)
{
    return (value >= 'A' && value <= 'Z') || (value >= 'a' && value <= 'z');
}

static int compare_word(const uint8_t *word, size_t word_length, const WordNode *node)
{
    const size_t common = word_length < node->word_length ? word_length : node->word_length;
    for (size_t i = 0; i < common; ++i) {
        if (word[i] < node->word[i]) return -1;
        if (word[i] > node->word[i]) return 1;
    }
    if (word_length < node->word_length) return -1;
    if (word_length > node->word_length) return 1;
    return 0;
}

static int create_node(WordNode *nodes, size_t *used,
                       const uint8_t *word, size_t word_length)
{
    if (*used >= MAX_UNIQUE_WORDS) return -1;
    const int index = (int)(*used);
    for (size_t i = 0; i < word_length; ++i) nodes[index].word[i] = word[i];
    nodes[index].word[word_length] = 0;
    nodes[index].word_length = word_length;
    nodes[index].frequency = 1;
    nodes[index].left = -1;
    nodes[index].right = -1;
    ++*used;
    return index;
}

static int insert_word(WordNode *nodes, size_t *used, int *root,
                       const uint8_t *word, size_t word_length)
{
    if (*root < 0) {
        *root = create_node(nodes, used, word, word_length);
        return *root >= 0;
    }
    int current = *root;
    for (;;) {
        const int order = compare_word(word, word_length, &nodes[current]);
        if (order == 0) {
            ++nodes[current].frequency;
            return 1;
        }
        int *child = order < 0 ? &nodes[current].left : &nodes[current].right;
        if (*child < 0) {
            *child = create_node(nodes, used, word, word_length);
            return *child >= 0;
        }
        current = *child;
    }
}

static int flush_token(uint8_t *token, size_t *token_length,
                       WordNode *nodes, size_t *used, int *root)
{
    if (*token_length == 0) return 1;
    if (token[*token_length - 1] == '-') --*token_length;
    if (*token_length > 0 && !insert_word(nodes, used, root, token, *token_length)) return 0;
    *token_length = 0;
    return 1;
}

static int append_byte(uint8_t *output, size_t *written, uint8_t value)
{
    if (*written >= MAX_OUTPUT_BYTES) return 0;
    output[(*written)++] = value;
    return 1;
}

static int build_output(const WordNode *nodes, int root, uint8_t *output, size_t *length)
{
    int stack[MAX_UNIQUE_WORDS];
    size_t top = 0;
    size_t written = 0;
    int current = root;
    while (current >= 0 || top > 0) {
        while (current >= 0) {
            if (top >= MAX_UNIQUE_WORDS) return 0;
            stack[top++] = current;
            current = nodes[current].left;
        }
        current = stack[--top];
        for (size_t i = 0; i < nodes[current].word_length; ++i)
            if (!append_byte(output, &written, nodes[current].word[i])) return 0;
        if (!append_byte(output, &written, '\t')) return 0;
        uint8_t reversed[20];
        size_t digits = 0;
        uint64_t frequency = nodes[current].frequency;
        do {
            reversed[digits++] = (uint8_t)('0' + frequency % 10);
            frequency /= 10;
        } while (frequency != 0);
        while (digits > 0)
            if (!append_byte(output, &written, reversed[--digits])) return 0;
        if (!append_byte(output, &written, '\n')) return 0;
        current = nodes[current].right;
    }
    *length = written;
    return 1;
}

int64_t word_frequency_bst(const int64_t *input, size_t length,
                           uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 1 || length > MAX_INPUT_BYTES + 2) return -1;
    if (input[0] < 0 || input[0] > MAX_INPUT_BYTES) return -1;
    const size_t text_length = (size_t)input[0];
    if (length != text_length + 1) return -1;
    for (size_t i = 0; i < text_length; ++i)
        if (input[i + 1] < 0 || input[i + 1] > 127) return -1;

    WordNode nodes[MAX_UNIQUE_WORDS];
    size_t used = 0;
    int root = -1;
    uint8_t token[MAX_TOKEN_BYTES + 1];
    size_t token_length = 0;
    for (size_t i = 0; i < text_length; ++i) {
        const uint8_t byte = (uint8_t)input[i + 1];
        if (ascii_alpha(byte)) {
            if (token_length >= MAX_TOKEN_BYTES) return -1;
            token[token_length++] = byte >= 'A' && byte <= 'Z' ? (uint8_t)(byte + 32) : byte;
        } else if ((byte == '\'' || byte == '-') && token_length > 0 && ascii_alpha(token[token_length - 1])) {
            if (token_length >= MAX_TOKEN_BYTES) return -1;
            token[token_length++] = byte;
        } else if (!flush_token(token, &token_length, nodes, &used, &root)) {
            return -1;
        }
    }
    if (!flush_token(token, &token_length, nodes, &used, &root)) return -1;

    uint8_t result[MAX_OUTPUT_BYTES];
    size_t result_length = 0;
    if (!build_output(nodes, root, result, &result_length)) return -1;
    if (output == NULL || capacity < result_length) return -2;
    for (size_t i = 0; i < result_length; ++i) output[i] = result[i];
    return (int64_t)result_length;
}
