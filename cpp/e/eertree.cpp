#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxTextLength = 128;
constexpr std::size_t kMaxNodes = kMaxTextLength + 2;
constexpr std::size_t kAlphabetSize = 26;

struct Node {
    int length = 0;
    int suffix_link = 0;
    std::array<int, kAlphabetSize> next{};

    Node() { next.fill(-1); }
};

using NodeArray = std::array<Node, kMaxNodes>;

int find_extendable(const NodeArray &nodes, const std::int64_t *text,
                    std::size_t position, int start)
{
    int node = start;
    for (;;) {
        const int preceding = static_cast<int>(position) - 1 - nodes[node].length;
        if (preceding >= 0 && text[static_cast<std::size_t>(preceding)] == text[position]) return node;
        node = nodes[node].suffix_link;
    }
}
} // namespace

extern "C" std::int64_t eertree(const std::int64_t *values, std::size_t length)
{
    if (values == nullptr || length < 1 || length > kMaxTextLength + 1) return -1;
    if (values[0] < 0 || values[0] > static_cast<std::int64_t>(kMaxTextLength)) return -1;
    const std::size_t text_length = static_cast<std::size_t>(values[0]);
    if (length != text_length + 1) return -1;
    for (std::size_t i = 0; i < text_length; ++i)
        if (values[i + 1] < 0 || values[i + 1] >= static_cast<std::int64_t>(kAlphabetSize)) return -1;

    NodeArray nodes{};
    nodes[0].length = -1;
    nodes[0].suffix_link = 0;
    nodes[1].length = 0;
    nodes[1].suffix_link = 0;
    int node_count = 2;
    int longest_suffix = 1;
    std::int64_t checksum = 0;
    const std::int64_t *text = values + 1;

    for (std::size_t position = 0; position < text_length; ++position) {
        const int letter = static_cast<int>(text[position]);
        const int parent = find_extendable(nodes, text, position, longest_suffix);
        int next = nodes[static_cast<std::size_t>(parent)].next[static_cast<std::size_t>(letter)];
        if (next < 0) {
            next = node_count++;
            Node &created = nodes[static_cast<std::size_t>(next)];
            created.length = nodes[static_cast<std::size_t>(parent)].length + 2;
            created.suffix_link = 0;
            nodes[static_cast<std::size_t>(parent)].next[static_cast<std::size_t>(letter)] = next;
            if (created.length == 1) {
                created.suffix_link = 1;
            } else {
                const int suffix_parent = find_extendable(nodes, text, position,
                    nodes[static_cast<std::size_t>(parent)].suffix_link);
                const int suffix = nodes[static_cast<std::size_t>(suffix_parent)].next[static_cast<std::size_t>(letter)];
                if (suffix < 0) return -1;
                created.suffix_link = suffix;
            }
        }
        longest_suffix = next;
        checksum += static_cast<std::int64_t>(position + 1) * (node_count - 2);
    }
    return checksum;
}
