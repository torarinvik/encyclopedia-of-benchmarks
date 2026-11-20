#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t max_operations = 64;
constexpr std::int64_t missing = -129;
constexpr std::size_t node_capacity = 2 * max_operations + 1;

struct Tree {
    std::array<int, node_capacity> left{};
    std::array<int, node_capacity> right{};
    std::array<int, node_capacity> size{};
    std::array<int, node_capacity> free_next{};
    std::array<std::int64_t, node_capacity> key{};
    std::array<std::int64_t, node_capacity> maximum{};
    int next_node = 1;
    int free_head = 0;

    int allocate() {
        int node;
        if (free_head != 0) {
            node = free_head;
            free_head = free_next[node];
        } else node = next_node++;
        left[node] = right[node] = size[node] = free_next[node] = 0;
        key[node] = maximum[node] = 0;
        return node;
    }
    void release(int node) {
        left[node] = right[node] = size[node] = 0;
        key[node] = maximum[node] = 0;
        free_next[node] = free_head;
        free_head = node;
    }
    int leaf(std::int64_t value) {
        const int node = allocate();
        key[node] = maximum[node] = value;
        size[node] = 1;
        return node;
    }
    int join(int a, int b) {
        const int node = allocate();
        left[node] = a;
        right[node] = b;
        size[node] = size[a] + size[b];
        maximum[node] = maximum[b];
        return node;
    }
    void cut(int node, int& a, int& b) {
        a = left[node];
        b = right[node];
        release(node);
    }
    static bool too_heavy(int a, int b) { return a > 3 * b; }
    int merge(int a, int b) {
        if (a == 0) return b;
        if (b == 0) return a;
        if (too_heavy(size[a], size[b])) {
            int x, y;
            cut(a, x, y);
            return rebalance(join(x, merge(y, b)));
        }
        if (too_heavy(size[b], size[a])) {
            int x, y;
            cut(b, x, y);
            return rebalance(join(merge(a, x), y));
        }
        return join(a, b);
    }
    int rebalance(int node) {
        if (size[node] == 1) return node;
        int a = left[node], b = right[node];
        if (too_heavy(size[a], size[b]) || too_heavy(size[b], size[a])) {
            cut(node, a, b);
            return merge(a, b);
        }
        return node;
    }
    int insert(int node, std::int64_t value) {
        if (node == 0) return leaf(value);
        if (size[node] == 1) {
            if (value <= key[node]) return join(leaf(value), node);
            return join(node, leaf(value));
        }
        if (value <= maximum[left[node]]) left[node] = insert(left[node], value);
        else right[node] = insert(right[node], value);
        size[node] = size[left[node]] + size[right[node]];
        maximum[node] = maximum[right[node]];
        return rebalance(node);
    }
    int remove(int node, std::int64_t value, bool& removed) {
        removed = false;
        if (node == 0) return 0;
        if (size[node] == 1) {
            if (key[node] != value) return node;
            release(node);
            removed = true;
            return 0;
        }
        if (value <= maximum[left[node]]) left[node] = remove(left[node], value, removed);
        else right[node] = remove(right[node], value, removed);
        if (!removed) return node;
        if (left[node] == 0 || right[node] == 0) {
            const int child = left[node] != 0 ? left[node] : right[node];
            release(node);
            return child;
        }
        size[node] = size[left[node]] + size[right[node]];
        maximum[node] = maximum[right[node]];
        return rebalance(node);
    }
    std::int64_t rank(int node, std::int64_t value) const {
        if (node == 0) return 0;
        if (size[node] == 1) return key[node] < value;
        const int a = left[node];
        return value <= maximum[a] ? rank(a, value) : size[a] + rank(right[node], value);
    }
    std::int64_t kth(int node, std::int64_t index) const {
        if (node == 0 || index >= size[node]) return missing;
        while (size[node] != 1) {
            const int a = left[node];
            if (index < size[a]) node = a;
            else { index -= size[a]; node = right[node]; }
        }
        return key[node];
    }
    std::int64_t predecessor(int node, std::int64_t value) const {
        if (node == 0) return missing;
        if (size[node] == 1) return key[node] < value ? key[node] : missing;
        const int a = left[node];
        if (value <= maximum[a]) return predecessor(a, value);
        const auto answer = predecessor(right[node], value);
        return answer == missing ? maximum[a] : answer;
    }
    std::int64_t successor(int node, std::int64_t value) const {
        if (node == 0) return missing;
        if (size[node] == 1) return key[node] > value ? key[node] : missing;
        const int a = left[node];
        return value < maximum[a] ? successor(a, value) : successor(right[node], value);
    }
};
}  // namespace

extern "C" std::int64_t weight_balanced_leaf_tree_order_statistics(
    const std::int64_t* input, std::size_t length) {
    if (input == nullptr || length < 1 || length > 130) return -1;
    const auto q = input[0];
    if (q < 0 || q > max_operations || length != static_cast<std::size_t>(1 + 2 * q)) return -1;
    for (std::int64_t i = 0; i < q; ++i) {
        const auto operation = input[1 + 2 * i];
        const auto argument = input[2 + 2 * i];
        if (operation < 0 || operation > 5) return -1;
        if (operation == 3) {
            if (argument < 0 || argument >= max_operations) return -1;
        } else if (argument < -128 || argument > 127) return -1;
    }
    Tree tree;
    int root = 0;
    std::int64_t checksum = 0;
    for (std::int64_t i = 0; i < q; ++i) {
        const auto operation = input[1 + 2 * i];
        const auto argument = input[2 + 2 * i];
        if (operation == 0) root = tree.insert(root, argument);
        else if (operation == 1) {
            bool removed = false;
            root = tree.remove(root, argument, removed);
        } else {
            std::int64_t answer;
            if (operation == 2) answer = tree.rank(root, argument);
            else if (operation == 3) answer = tree.kth(root, argument);
            else if (operation == 4) answer = tree.predecessor(root, argument);
            else answer = tree.successor(root, argument);
            checksum += (i + 1) * (answer - missing);
        }
    }
    return checksum;
}
