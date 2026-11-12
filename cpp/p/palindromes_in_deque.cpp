#include <cstddef>
#include <cstdint>

namespace {
constexpr int kMaxQueries = 32;
constexpr int kMaxText = 32;
constexpr int kMaxNodes = kMaxText + 2;
constexpr int kAlphabet = 26;

struct EertreeNode {
    int length = 0;
    int link = 0;
    int next[kAlphabet];
};

int extendable(const EertreeNode *nodes, const int *text, int position,
               int node) {
    for (;;) {
        const int preceding = position - nodes[node].length - 1;
        if (preceding >= 0 && text[preceding] == text[position]) return node;
        node = nodes[node].link;
    }
}

void summarize(const int *text, int size, std::int64_t &distinct,
               std::int64_t &prefix, std::int64_t &suffix) {
    EertreeNode nodes[kMaxNodes]{};
    for (auto &node : nodes)
        for (int &next : node.next) next = -1;
    nodes[0].length = -1;
    int node_count = 2;
    int last = 1;
    prefix = 0;
    for (int position = 0; position < size; ++position) {
        const int letter = text[position];
        const int parent = extendable(nodes, text, position, last);
        int next = nodes[parent].next[letter];
        if (next < 0) {
            next = node_count++;
            nodes[next].length = nodes[parent].length + 2;
            if (nodes[next].length == 1) {
                nodes[next].link = 1;
            } else {
                const int suffix_parent =
                    extendable(nodes, text, position, nodes[parent].link);
                nodes[next].link = nodes[suffix_parent].next[letter];
            }
            nodes[parent].next[letter] = next;
        }
        last = next;
        if (nodes[last].length == position + 1) prefix = position + 1;
    }
    distinct = node_count - 2;
    suffix = nodes[last].length;
}

void store_i64_le(std::uint8_t *output, std::size_t offset,
                  std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}  // namespace

extern "C" std::int64_t palindromes_in_deque(
    const std::int64_t *input, std::size_t length, std::uint8_t *output,
    std::size_t capacity) {
    if (input == nullptr || length < 1 || length > 1 + 2 * kMaxQueries) return -1;
    const auto query_value = input[0];
    if (query_value < 1 || query_value > kMaxQueries) return -1;
    const auto queries = static_cast<std::size_t>(query_value);
    if (length != 1 + 2 * queries) return -1;

    int size = 0;
    for (std::size_t query = 0; query < queries; ++query) {
        const auto operation = input[1 + 2 * query];
        const auto letter = input[2 + 2 * query];
        if (operation == 0 || operation == 1) {
            if (letter < 0 || letter >= kAlphabet) return -1;
            ++size;
        } else if (operation == 2 || operation == 3) {
            if (letter != 0 || size == 0) return -1;
            --size;
        } else {
            return -1;
        }
    }
    if (output == nullptr || capacity < 24 * queries) return -2;

    int text[kMaxText];
    size = 0;
    for (std::size_t query = 0; query < queries; ++query) {
        const int operation = static_cast<int>(input[1 + 2 * query]);
        const int letter = static_cast<int>(input[2 + 2 * query]);
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
        std::int64_t distinct, prefix, suffix;
        summarize(text, size, distinct, prefix, suffix);
        const auto offset = 24 * query;
        store_i64_le(output, offset, distinct);
        store_i64_le(output, offset + 8, prefix);
        store_i64_le(output, offset + 16, suffix);
    }
    return static_cast<std::int64_t>(24 * queries);
}
