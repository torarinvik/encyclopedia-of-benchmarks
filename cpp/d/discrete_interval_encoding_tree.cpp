#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int kMaxQ = 32;
constexpr int kArena = 64;
constexpr std::int64_t kMinKey = -15;
constexpr std::int64_t kMaxKey = 15;

struct Node {
    std::int64_t lo = 0;
    std::int64_t hi = 0;
    int left = -1;
    int right = -1;
};

int new_node(std::array<Node, kArena>& nodes, int& used, std::int64_t lo,
             std::int64_t hi, int left = -1, int right = -1) {
    const int index = used++;
    nodes[static_cast<std::size_t>(index)] = Node{lo, hi, left, right};
    return index;
}

int pop_max(std::array<Node, kArena>& nodes, int root, std::int64_t& lo,
            std::int64_t& hi) {
    Node& node = nodes[static_cast<std::size_t>(root)];
    if (node.right < 0) {
        lo = node.lo;
        hi = node.hi;
        return node.left;
    }
    node.right = pop_max(nodes, node.right, lo, hi);
    return root;
}

int pop_min(std::array<Node, kArena>& nodes, int root, std::int64_t& lo,
            std::int64_t& hi) {
    Node& node = nodes[static_cast<std::size_t>(root)];
    if (node.left < 0) {
        lo = node.lo;
        hi = node.hi;
        return node.right;
    }
    node.left = pop_min(nodes, node.left, lo, hi);
    return root;
}

void max_interval(const std::array<Node, kArena>& nodes, int root,
                  std::int64_t& lo, std::int64_t& hi) {
    while (nodes[static_cast<std::size_t>(root)].right >= 0)
        root = nodes[static_cast<std::size_t>(root)].right;
    lo = nodes[static_cast<std::size_t>(root)].lo;
    hi = nodes[static_cast<std::size_t>(root)].hi;
}

void min_interval(const std::array<Node, kArena>& nodes, int root,
                  std::int64_t& lo, std::int64_t& hi) {
    while (nodes[static_cast<std::size_t>(root)].left >= 0)
        root = nodes[static_cast<std::size_t>(root)].left;
    lo = nodes[static_cast<std::size_t>(root)].lo;
    hi = nodes[static_cast<std::size_t>(root)].hi;
}

int insert(std::array<Node, kArena>& nodes, int& used, int root,
           std::int64_t key, int& interval_count, bool& changed) {
    if (root < 0) {
        ++interval_count;
        changed = true;
        return new_node(nodes, used, key, key);
    }
    Node& node = nodes[static_cast<std::size_t>(root)];
    if (key < node.lo) {
        if (key + 1 == node.lo) {
            node.lo = key;
            changed = true;
            if (node.left >= 0) {
                std::int64_t pred_lo, pred_hi;
                max_interval(nodes, node.left, pred_lo, pred_hi);
                if (pred_hi + 1 == key) {
                    node.left = pop_max(nodes, node.left, pred_lo, pred_hi);
                    node.lo = pred_lo;
                    --interval_count;
                }
            }
        } else {
            node.left = insert(nodes, used, node.left, key, interval_count, changed);
        }
        return root;
    }
    if (key > node.hi) {
        if (key == node.hi + 1) {
            node.hi = key;
            changed = true;
            if (node.right >= 0) {
                std::int64_t succ_lo, succ_hi;
                min_interval(nodes, node.right, succ_lo, succ_hi);
                if (key + 1 == succ_lo) {
                    node.right = pop_min(nodes, node.right, succ_lo, succ_hi);
                    node.hi = succ_hi;
                    --interval_count;
                }
            }
        } else {
            node.right = insert(nodes, used, node.right, key, interval_count, changed);
        }
        return root;
    }
    changed = false;
    return root;
}

int erase(std::array<Node, kArena>& nodes, int& used, int root,
          std::int64_t key, int& interval_count, bool& changed) {
    if (root < 0) {
        changed = false;
        return root;
    }
    Node& node = nodes[static_cast<std::size_t>(root)];
    if (key < node.lo) {
        node.left = erase(nodes, used, node.left, key, interval_count, changed);
        return root;
    }
    if (key > node.hi) {
        node.right = erase(nodes, used, node.right, key, interval_count, changed);
        return root;
    }
    changed = true;
    if (node.lo == node.hi) {
        --interval_count;
        if (node.left < 0) return node.right;
        if (node.right < 0) return node.left;
        std::int64_t pred_lo, pred_hi;
        node.left = pop_max(nodes, node.left, pred_lo, pred_hi);
        node.lo = pred_lo;
        node.hi = pred_hi;
        return root;
    }
    if (key == node.lo) {
        ++node.lo;
        return root;
    }
    if (key == node.hi) {
        --node.hi;
        return root;
    }
    const int right_piece = new_node(nodes, used, key + 1, node.hi, -1, node.right);
    Node& refreshed = nodes[static_cast<std::size_t>(root)];
    refreshed.hi = key - 1;
    refreshed.right = right_piece;
    ++interval_count;
    return root;
}

bool contains(const std::array<Node, kArena>& nodes, int root, std::int64_t key) {
    while (root >= 0) {
        const Node& node = nodes[static_cast<std::size_t>(root)];
        if (key < node.lo) root = node.left;
        else if (key > node.hi) root = node.right;
        else return true;
    }
    return false;
}
} // namespace

extern "C" std::int64_t discrete_interval_encoding_tree(
    const std::int64_t* input, std::size_t length, std::uint8_t* output,
    std::size_t capacity) {
    if (input == nullptr || length < 1 || length > 2 + 2 * kMaxQ) return -1;
    if (input[0] < 0 || input[0] > kMaxQ) return -1;
    const int q = static_cast<int>(input[0]);
    if (length != 1 + 2 * static_cast<std::size_t>(q)) return -1;
    for (int i = 0; i < q; ++i) {
        const auto opcode = input[1 + 2 * static_cast<std::size_t>(i)];
        const auto key = input[2 + 2 * static_cast<std::size_t>(i)];
        if (opcode < 0 || opcode > 2 || key < kMinKey || key > kMaxKey) return -1;
    }
    const std::size_t required = 8 * static_cast<std::size_t>(q);
    if ((required > 0 && output == nullptr) || capacity < required) return -2;

    std::array<Node, kArena> nodes{};
    int used = 0, root = -1, cardinality = 0, interval_count = 0;
    std::array<std::int64_t, kMaxQ> staged{};
    for (int i = 0; i < q; ++i) {
        const auto opcode = input[1 + 2 * static_cast<std::size_t>(i)];
        const auto key = input[2 + 2 * static_cast<std::size_t>(i)];
        bool changed = false;
        if (opcode == 0) {
            root = insert(nodes, used, root, key, interval_count, changed);
            if (changed) ++cardinality;
        } else if (opcode == 1) {
            root = erase(nodes, used, root, key, interval_count, changed);
            if (changed) --cardinality;
        }
        staged[static_cast<std::size_t>(i)] = 64LL * cardinality + 2LL * interval_count +
            static_cast<std::int64_t>(contains(nodes, root, key));
    }
    for (int i = 0; i < q; ++i) {
        const auto bytes = static_cast<std::uint64_t>(staged[static_cast<std::size_t>(i)]);
        for (int b = 0; b < 8; ++b)
            output[8 * static_cast<std::size_t>(i) + static_cast<std::size_t>(b)] =
                static_cast<std::uint8_t>(bytes >> (8 * b));
    }
    return static_cast<std::int64_t>(required);
}
