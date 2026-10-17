/* Bounded projection of the pinned ASCII tokenizer and unbalanced BST. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_INPUT_BYTES = 256;
constexpr std::size_t MAX_TOKEN_BYTES = 45;
constexpr std::size_t MAX_UNIQUE_WORDS = 128;
constexpr std::size_t MAX_OUTPUT_BYTES = 896;

struct WordNode {
    std::uint8_t word[MAX_TOKEN_BYTES + 1]{};
    std::size_t word_length = 0;
    std::uint64_t frequency = 0;
    int left = -1;
    int right = -1;
};

bool ascii_alpha(std::uint8_t value) noexcept
{
    return (value >= 'A' && value <= 'Z') || (value >= 'a' && value <= 'z');
}

int compare_word(const std::uint8_t *word, std::size_t word_length, const WordNode &node) noexcept
{
    const std::size_t common = word_length < node.word_length ? word_length : node.word_length;
    for (std::size_t i = 0; i < common; ++i) {
        if (word[i] < node.word[i]) return -1;
        if (word[i] > node.word[i]) return 1;
    }
    if (word_length < node.word_length) return -1;
    if (word_length > node.word_length) return 1;
    return 0;
}

int create_node(WordNode *nodes, std::size_t &used,
                const std::uint8_t *word, std::size_t word_length) noexcept
{
    if (used >= MAX_UNIQUE_WORDS) return -1;
    const int index = static_cast<int>(used++);
    for (std::size_t i = 0; i < word_length; ++i) nodes[index].word[i] = word[i];
    nodes[index].word[word_length] = 0;
    nodes[index].word_length = word_length;
    nodes[index].frequency = 1;
    nodes[index].left = -1;
    nodes[index].right = -1;
    return index;
}

bool insert_word(WordNode *nodes, std::size_t &used, int &root,
                 const std::uint8_t *word, std::size_t word_length) noexcept
{
    if (root < 0) {
        root = create_node(nodes, used, word, word_length);
        return root >= 0;
    }
    int current = root;
    for (;;) {
        const int order = compare_word(word, word_length, nodes[current]);
        if (order == 0) {
            ++nodes[current].frequency;
            return true;
        }
        int &child = order < 0 ? nodes[current].left : nodes[current].right;
        if (child < 0) {
            child = create_node(nodes, used, word, word_length);
            return child >= 0;
        }
        current = child;
    }
}

bool flush_token(std::uint8_t *token, std::size_t &token_length,
                 WordNode *nodes, std::size_t &used, int &root) noexcept
{
    if (token_length == 0) return true;
    if (token[token_length - 1] == '-') --token_length;
    if (token_length > 0 && !insert_word(nodes, used, root, token, token_length)) return false;
    token_length = 0;
    return true;
}

bool append_byte(std::uint8_t *output, std::size_t &written, std::uint8_t value) noexcept
{
    if (written >= MAX_OUTPUT_BYTES) return false;
    output[written++] = value;
    return true;
}

bool build_output(const WordNode *nodes, int root,
                  std::uint8_t *output, std::size_t &length) noexcept
{
    int stack[MAX_UNIQUE_WORDS];
    std::size_t top = 0, written = 0;
    int current = root;
    while (current >= 0 || top > 0) {
        while (current >= 0) {
            if (top >= MAX_UNIQUE_WORDS) return false;
            stack[top++] = current;
            current = nodes[current].left;
        }
        current = stack[--top];
        for (std::size_t i = 0; i < nodes[current].word_length; ++i)
            if (!append_byte(output, written, nodes[current].word[i])) return false;
        if (!append_byte(output, written, '\t')) return false;
        std::uint8_t reversed[20];
        std::size_t digits = 0;
        std::uint64_t frequency = nodes[current].frequency;
        do {
            reversed[digits++] = static_cast<std::uint8_t>('0' + frequency % 10);
            frequency /= 10;
        } while (frequency != 0);
        while (digits > 0) if (!append_byte(output, written, reversed[--digits])) return false;
        if (!append_byte(output, written, '\n')) return false;
        current = nodes[current].right;
    }
    length = written;
    return true;
}
}

extern "C" std::int64_t word_frequency_bst(const std::int64_t *input,
    std::size_t length, std::uint8_t *output, std::size_t capacity) noexcept
{
    if (input == nullptr || length < 1 || length > MAX_INPUT_BYTES + 2) return -1;
    if (input[0] < 0 || input[0] > static_cast<std::int64_t>(MAX_INPUT_BYTES)) return -1;
    const std::size_t text_length = static_cast<std::size_t>(input[0]);
    if (length != text_length + 1) return -1;
    for (std::size_t i = 0; i < text_length; ++i)
        if (input[i + 1] < 0 || input[i + 1] > 127) return -1;

    WordNode nodes[MAX_UNIQUE_WORDS]{};
    std::size_t used = 0;
    int root = -1;
    std::uint8_t token[MAX_TOKEN_BYTES + 1]{};
    std::size_t token_length = 0;
    for (std::size_t i = 0; i < text_length; ++i) {
        const std::uint8_t byte = static_cast<std::uint8_t>(input[i + 1]);
        if (ascii_alpha(byte)) {
            if (token_length >= MAX_TOKEN_BYTES) return -1;
            token[token_length++] = byte >= 'A' && byte <= 'Z' ? static_cast<std::uint8_t>(byte + 32) : byte;
        } else if ((byte == '\'' || byte == '-') && token_length > 0 && ascii_alpha(token[token_length - 1])) {
            if (token_length >= MAX_TOKEN_BYTES) return -1;
            token[token_length++] = byte;
        } else if (!flush_token(token, token_length, nodes, used, root)) {
            return -1;
        }
    }
    if (!flush_token(token, token_length, nodes, used, root)) return -1;

    std::uint8_t result[MAX_OUTPUT_BYTES];
    std::size_t result_length = 0;
    if (!build_output(nodes, root, result, result_length)) return -1;
    if (output == nullptr || capacity < result_length) return -2;
    for (std::size_t i = 0; i < result_length; ++i) output[i] = result[i];
    return static_cast<std::int64_t>(result_length);
}
