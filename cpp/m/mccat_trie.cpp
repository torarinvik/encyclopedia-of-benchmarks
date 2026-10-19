#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxWords = 64;
constexpr std::size_t kMaxWordLength = 32;
constexpr std::size_t kMaxInputValues = 1 + kMaxWords * (1 + kMaxWordLength);
constexpr std::size_t kMaxNodes = kMaxWords * kMaxWordLength;
constexpr std::size_t kMaxOutputBytes = kMaxWords * (kMaxWordLength + 1);

struct TrieNode {
    std::uint8_t value = 0;
    bool terminal = false;
    std::size_t postfix = 0;
    std::size_t otherChar = 0;
};

using NodePool = std::array<TrieNode, kMaxNodes + 1>;

std::size_t newNode(NodePool& nodes, std::size_t& used, std::uint8_t value) {
    const std::size_t node = ++used;
    nodes[node].value = value;
    return node;
}

std::size_t newSuffix(NodePool& nodes, std::size_t& used, const std::int64_t* input,
                      std::size_t start, std::size_t length) {
    const std::size_t root = newNode(nodes, used, static_cast<std::uint8_t>(input[start]));
    std::size_t current = root;
    for (std::size_t i = 1; i < length; ++i) {
        const std::size_t child = newNode(nodes, used, static_cast<std::uint8_t>(input[start + i]));
        nodes[current].postfix = child;
        current = child;
    }
    nodes[current].terminal = true;
    return root;
}

void insertWord(NodePool& nodes, std::size_t& used, std::size_t current,
                const std::int64_t* input, std::size_t start,
                std::size_t length, std::size_t offset) {
    if (nodes[current].value == static_cast<std::uint8_t>(input[start + offset])) {
        if (offset + 1 == length) nodes[current].terminal = true;
        else if (nodes[current].postfix == 0)
            nodes[current].postfix = newSuffix(nodes, used, input, start + offset + 1, length - offset - 1);
        else insertWord(nodes, used, nodes[current].postfix, input, start, length, offset + 1);
    } else if (nodes[current].otherChar == 0) {
        nodes[current].otherChar = newSuffix(nodes, used, input, start + offset, length - offset);
    } else insertWord(nodes, used, nodes[current].otherChar, input, start, length, offset);
}

void measureOutput(const NodePool& nodes, std::size_t current, std::size_t depth, std::size_t& length) {
    if (current == 0) return;
    if (nodes[current].terminal) length += depth + 2;
    measureOutput(nodes, nodes[current].postfix, depth + 1, length);
    measureOutput(nodes, nodes[current].otherChar, depth, length);
}

void emitOutput(const NodePool& nodes, std::size_t current, std::size_t depth,
                std::array<std::uint8_t, kMaxWordLength>& prefix,
                std::uint8_t* output, std::size_t& position) {
    if (current == 0) return;
    prefix[depth] = nodes[current].value;
    if (nodes[current].terminal) {
        for (std::size_t i = 0; i <= depth; ++i) output[position++] = prefix[i];
        output[position++] = '\n';
    }
    emitOutput(nodes, nodes[current].postfix, depth + 1, prefix, output, position);
    emitOutput(nodes, nodes[current].otherChar, depth, prefix, output, position);
}
} // namespace

extern "C" std::int64_t mccat_trie(const std::int64_t* input, std::size_t length,
                                    std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length < 1 || length > kMaxInputValues) return -1;
    if (input[0] < 0 || input[0] > static_cast<std::int64_t>(kMaxWords)) return -1;
    const std::size_t wordCount = static_cast<std::size_t>(input[0]);
    std::array<std::size_t, kMaxWords> starts{};
    std::array<std::size_t, kMaxWords> lengths{};
    std::size_t position = 1;
    for (std::size_t i = 0; i < wordCount; ++i) {
        if (position >= length) return -1;
        const std::int64_t wordLengthValue = input[position++];
        if (wordLengthValue < 1 || wordLengthValue > static_cast<std::int64_t>(kMaxWordLength)) return -1;
        const std::size_t wordLength = static_cast<std::size_t>(wordLengthValue);
        if (wordLength > length - position) return -1;
        starts[i] = position;
        lengths[i] = wordLength;
        for (std::size_t j = 0; j < wordLength; ++j)
            if (input[position + j] < 33 || input[position + j] > 126) return -1;
        position += wordLength;
    }
    if (position != length) return -1;

    NodePool nodes{};
    std::size_t used = 0, root = 0;
    for (std::size_t i = 0; i < wordCount; ++i) {
        if (root == 0) root = newSuffix(nodes, used, input, starts[i], lengths[i]);
        else insertWord(nodes, used, root, input, starts[i], lengths[i], 0);
    }
    std::size_t outputLength = 0;
    measureOutput(nodes, root, 0, outputLength);
    if (outputLength > kMaxOutputBytes) return -1;
    if (outputLength != 0 && (output == nullptr || capacity < outputLength)) return -2;
    if (outputLength == 0) return 0;
    std::array<std::uint8_t, kMaxWordLength> prefix{};
    std::size_t written = 0;
    emitOutput(nodes, root, 0, prefix, output, written);
    return static_cast<std::int64_t>(written);
}
