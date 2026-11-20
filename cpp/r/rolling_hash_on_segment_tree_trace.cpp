#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int max_n = 20;
constexpr int max_q = 20;
constexpr std::size_t max_parseable_input = 123;
constexpr int tree_capacity = 64;
constexpr std::int64_t hash_mod = 1000000007;
constexpr std::int64_t hash_base = 911382323;

struct Node {
    std::int64_t hash = 0;
    int length = 0;
};

std::int64_t concatenate_hash(std::int64_t left_hash, std::int64_t right_hash,
                              int right_length,
                              const std::array<std::int64_t, max_n + 1> &powers) noexcept {
    return (left_hash * powers[static_cast<std::size_t>(right_length)] + right_hash) % hash_mod;
}

void pull(std::array<Node, tree_capacity> &tree, int node,
          const std::array<std::int64_t, max_n + 1> &powers) noexcept {
    const Node &left = tree[static_cast<std::size_t>(2 * node)];
    const Node &right = tree[static_cast<std::size_t>(2 * node + 1)];
    Node &parent = tree[static_cast<std::size_t>(node)];
    parent.hash = concatenate_hash(left.hash, right.hash, right.length, powers);
    parent.length = left.length + right.length;
}

std::int64_t range_hash(const std::array<Node, tree_capacity> &tree, int tree_size,
                        int left, int right,
                        const std::array<std::int64_t, max_n + 1> &powers) noexcept {
    std::int64_t left_hash = 0, right_hash = 0;
    int right_length = 0;
    left += tree_size;
    right += tree_size;
    while (left < right) {
        if ((left & 1) != 0) {
            const Node &part = tree[static_cast<std::size_t>(left++)];
            left_hash = concatenate_hash(left_hash, part.hash, part.length, powers);
        }
        if ((right & 1) != 0) {
            const Node &part = tree[static_cast<std::size_t>(--right)];
            right_hash = concatenate_hash(part.hash, right_hash, right_length, powers);
            right_length += part.length;
        }
        left /= 2;
        right /= 2;
    }
    return concatenate_hash(left_hash, right_hash, right_length, powers);
}
}

extern "C" std::int64_t rolling_hash_on_segment_tree_trace(const std::int64_t *input,
                                                            std::size_t length) noexcept {
    if (input == nullptr || length < 2 || length > max_parseable_input) return -1;
    if (input[0] < 0 || input[0] > max_n || input[1] < 0 || input[1] > max_q) return -1;
    const int n = static_cast<int>(input[0]);
    const int q = static_cast<int>(input[1]);
    if (length != 2 + static_cast<std::size_t>(n) + 5 * static_cast<std::size_t>(q)) return -1;

    std::array<std::int64_t, max_n + 1> powers{};
    powers[0] = 1;
    for (int i = 1; i <= max_n; ++i)
        powers[static_cast<std::size_t>(i)] = (powers[static_cast<std::size_t>(i - 1)] * hash_base) % hash_mod;

    int tree_size = 1;
    while (tree_size < n) tree_size *= 2;
    std::array<Node, tree_capacity> tree{};
    for (int i = 0; i < n; ++i) {
        const std::int64_t symbol = input[2 + static_cast<std::size_t>(i)];
        if (symbol < 0 || symbol > 25) return -1;
        Node &leaf = tree[static_cast<std::size_t>(tree_size + i)];
        leaf.hash = symbol;
        leaf.length = 1;
    }
    for (int node = tree_size - 1; node > 0; --node) pull(tree, node, powers);

    std::int64_t checksum = 0;
    for (int operation = 0; operation < q; ++operation) {
        const std::size_t at = 2 + static_cast<std::size_t>(n) + 5 * static_cast<std::size_t>(operation);
        const std::int64_t opcode = input[at];
        const std::int64_t a = input[at + 1], b = input[at + 2];
        const std::int64_t c = input[at + 3], d = input[at + 4];
        int response = 0;

        if (opcode == 0) {
            if (a < 0 || a >= n || b < 0 || b > 25 || c != 0 || d != 0) return -1;
            int node = tree_size + static_cast<int>(a);
            Node &leaf = tree[static_cast<std::size_t>(node)];
            leaf.hash = b;
            leaf.length = 1;
            while (node > 1) {
                node /= 2;
                pull(tree, node, powers);
            }
        } else if (opcode == 1) {
            if (a < 0 || a > b || b > n || c < 0 || c > d || d > n) return -1;
            if (b - a == d - c)
                response = range_hash(tree, tree_size, static_cast<int>(a), static_cast<int>(b), powers) ==
                           range_hash(tree, tree_size, static_cast<int>(c), static_cast<int>(d), powers);
        } else {
            return -1;
        }
        checksum += static_cast<std::int64_t>(operation + 1) * (opcode * 2 + response + 1);
    }
    return checksum;
}
