#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int kMaxText = 64;
constexpr int kMaxNodes = kMaxText + 2;
constexpr int kAlphabet = 4;

struct Node {
    int length = 0;
    int link = 0;
    int difference = 0;
    int series_link = 1;
    int series_best = 0;
    int series_start = 0;
    std::array<int, kAlphabet> next{};
};

int find_extendable(const std::array<Node, kMaxNodes>& nodes,
                    const std::array<int, kMaxText>& text, int position, int start) {
    int node = start;
    for (;;) {
        const int preceding = position - 1 - nodes[node].length;
        if (preceding >= 0 && text[preceding] == text[position]) return node;
        node = nodes[node].link;
    }
}

void put_i64(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (int byte = 0; byte < 8; ++byte)
        output[offset + static_cast<std::size_t>(byte)] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
} // namespace

extern "C" std::int64_t palindromic_partition_series_links(
    const std::int64_t* input, std::size_t length,
    std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length < 1 || length > kMaxText + 2) return -1;
    if (input[0] < 0 || input[0] > kMaxText) return -1;
    const int n = static_cast<int>(input[0]);
    if (length != static_cast<std::size_t>(n + 1)) return -1;
    std::array<int, kMaxText> text{};
    for (int i = 0; i < n; ++i) {
        if (input[i + 1] < 0 || input[i + 1] >= kAlphabet) return -1;
        text[i] = static_cast<int>(input[i + 1]);
    }

    std::array<Node, kMaxNodes> nodes{};
    nodes[0].length = 0; nodes[0].link = 1;
    nodes[1].length = -1; nodes[1].link = 1;
    int node_count = 2;
    int last = 0;
    std::array<int, kMaxText + 1> dp{};
    std::array<int, kMaxText + 1> predecessor{};
    dp.fill(kMaxText + 1);
    dp[0] = 0;

    for (int position = 0; position < n; ++position) {
        const int end = position + 1;
        const int symbol = text[position];
        const int parent = find_extendable(nodes, text, position, last);
        int next = nodes[parent].next[symbol];
        if (next == 0) {
            next = node_count++;
            nodes[next].length = nodes[parent].length + 2;
            nodes[next].link = 0;
            nodes[parent].next[symbol] = next;
            if (nodes[next].length == 1) {
                nodes[next].link = 0;
            } else {
                const int suffix_parent = find_extendable(nodes, text, position, nodes[parent].link);
                nodes[next].link = nodes[suffix_parent].next[symbol];
            }
            const int fail = nodes[next].link;
            nodes[next].difference = nodes[next].length - nodes[fail].length;
            nodes[next].series_link = nodes[next].difference == nodes[fail].difference
                ? nodes[fail].series_link : fail;
        }
        last = next;
        int best_value = kMaxText + 1;
        int best_start = end;
        for (int node = last; nodes[node].length > 0; node = nodes[node].series_link) {
            const int start = end - nodes[nodes[node].series_link].length - nodes[node].difference;
            nodes[node].series_best = dp[start];
            nodes[node].series_start = start;
            const int fail = nodes[node].link;
            if (nodes[node].difference == nodes[fail].difference &&
                (nodes[fail].series_best < nodes[node].series_best ||
                 (nodes[fail].series_best == nodes[node].series_best &&
                  nodes[fail].series_start < nodes[node].series_start))) {
                nodes[node].series_best = nodes[fail].series_best;
                nodes[node].series_start = nodes[fail].series_start;
            }
            const int candidate = nodes[node].series_best + 1;
            if (candidate < best_value ||
                (candidate == best_value && nodes[node].series_start < best_start)) {
                best_value = candidate;
                best_start = nodes[node].series_start;
            }
        }
        dp[end] = best_value;
        predecessor[end] = best_start;
    }

    std::array<int, kMaxText> reverse_pieces{};
    int piece_count = 0;
    for (int end = n; end > 0; end = predecessor[end])
        reverse_pieces[piece_count++] = end - predecessor[end];
    std::array<std::int64_t, kMaxText + 1> words{};
    std::size_t word_count = 0;
    words[word_count++] = piece_count;
    for (int i = piece_count - 1; i >= 0; --i) words[word_count++] = reverse_pieces[i];
    const std::size_t bytes = word_count * 8;
    if (output == nullptr || capacity < bytes) return -2;
    for (std::size_t i = 0; i < word_count; ++i) put_i64(output, i * 8, words[i]);
    return static_cast<std::int64_t>(bytes);
}
