#include <algorithm>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t MAX_ITEMS = 32, MAX_OPS = 32, MAX_KEY = 1000;
struct Tree {
    std::int64_t key[65]{};
    int height[65]{};
    int size[65]{};
    int left[65]{};
    int right[65]{};
    int used = 0;
};
int height(const Tree& tree, int node) { return node == 0 ? 0 : tree.height[node]; }
int size(const Tree& tree, int node) { return node == 0 ? 0 : tree.size[node]; }
void refresh(Tree& tree, int node) {
    tree.height[node] = std::max(height(tree, tree.left[node]), height(tree, tree.right[node])) + 1;
    tree.size[node] = size(tree, tree.left[node]) + size(tree, tree.right[node]) + 1;
}
int rotate_right(Tree& tree, int root) {
    const int pivot = tree.left[root];
    tree.left[root] = tree.right[pivot]; tree.right[pivot] = root;
    refresh(tree, root); refresh(tree, pivot);
    return pivot;
}
int rotate_left(Tree& tree, int root) {
    const int pivot = tree.right[root];
    tree.right[root] = tree.left[pivot]; tree.left[pivot] = root;
    refresh(tree, root); refresh(tree, pivot);
    return pivot;
}
int rebalance(Tree& tree, int root) {
    refresh(tree, root);
    const int difference = height(tree, tree.left[root]) - height(tree, tree.right[root]);
    if (difference > 1) {
        const int child = tree.left[root];
        if (height(tree, tree.left[child]) < height(tree, tree.right[child])) tree.left[root] = rotate_left(tree, child);
        return rotate_right(tree, root);
    }
    if (difference < -1) {
        const int child = tree.right[root];
        if (height(tree, tree.right[child]) < height(tree, tree.left[child])) tree.right[root] = rotate_right(tree, child);
        return rotate_left(tree, root);
    }
    return root;
}
int insert_key(Tree& tree, int root, std::int64_t key) {
    if (!root) { const int node = ++tree.used; tree.key[node] = key; tree.height[node] = tree.size[node] = 1; return node; }
    if (key < tree.key[root]) tree.left[root] = insert_key(tree, tree.left[root], key);
    else if (key > tree.key[root]) tree.right[root] = insert_key(tree, tree.right[root], key);
    else return root;
    return rebalance(tree, root);
}
int minimum_node(const Tree& tree, int root) { while (tree.left[root]) root = tree.left[root]; return root; }
int erase_key(Tree& tree, int root, std::int64_t key) {
    if (!root) return 0;
    if (key < tree.key[root]) tree.left[root] = erase_key(tree, tree.left[root], key);
    else if (key > tree.key[root]) tree.right[root] = erase_key(tree, tree.right[root], key);
    else if (!tree.left[root]) return tree.right[root];
    else if (!tree.right[root]) return tree.left[root];
    else { const int next = minimum_node(tree, tree.right[root]); tree.key[root] = tree.key[next]; tree.right[root] = erase_key(tree, tree.right[root], tree.key[next]); }
    return rebalance(tree, root);
}
std::int64_t kth(const Tree& tree, int root, std::int64_t rank) {
    if (rank < 1 || rank > size(tree, root)) return -1;
    while (root) { const int left_count = size(tree, tree.left[root]); if (rank == left_count + 1) return tree.key[root]; if (rank <= left_count) root = tree.left[root]; else { rank -= left_count + 1; root = tree.right[root]; } }
    return -1;
}
std::int64_t count_le(const Tree& tree, int root, std::int64_t key) {
    std::int64_t count = 0;
    while (root) { if (tree.key[root] <= key) { count += size(tree, tree.left[root]) + 1; root = tree.right[root]; } else root = tree.left[root]; }
    return count;
}
std::int64_t predecessor(const Tree& tree, int root, std::int64_t key) {
    std::int64_t answer = -1;
    while (root) { if (tree.key[root] <= key) { answer = tree.key[root]; root = tree.right[root]; } else root = tree.left[root]; }
    return answer;
}
std::int64_t successor(const Tree& tree, int root, std::int64_t key) {
    std::int64_t answer = -1;
    while (root) { if (tree.key[root] >= key) { answer = tree.key[root]; root = tree.left[root]; } else root = tree.right[root]; }
    return answer;
}
}

extern "C" std::int64_t ordered_set_avl_order_statistics(const std::int64_t* input, std::size_t length) noexcept {
    if (!input || length < 2 || length > 99) return -1;
    const auto n = input[0], q = input[1];
    if (n < 0 || n > MAX_ITEMS || q < 0 || q > MAX_OPS || length != static_cast<std::size_t>(2 + n + 2 * q)) return -1;
    for (std::int64_t i = 0; i < n; ++i) { const auto key = input[2 + i]; if (key < 0 || key > MAX_KEY || (i > 0 && input[1 + i] >= key)) return -1; }
    for (std::int64_t i = 0; i < q; ++i) { const auto op = input[2 + n + 2 * i], key = input[3 + n + 2 * i]; if (op < 0 || op > 5 || key < 0 || key > MAX_KEY || (op == 2 && key < 1)) return -1; }
    Tree tree{};
    int root = 0;
    for (std::int64_t i = 0; i < n; ++i) root = insert_key(tree, root, input[2 + i]);
    std::int64_t checksum = 0, query_index = 0;
    for (std::int64_t i = 0; i < q; ++i) {
        const auto op = input[2 + n + 2 * i], key = input[3 + n + 2 * i];
        if (op == 0) root = insert_key(tree, root, key);
        else if (op == 1) root = erase_key(tree, root, key);
        else { const auto answer = op == 2 ? kth(tree, root, key) : op == 3 ? count_le(tree, root, key) : op == 4 ? predecessor(tree, root, key) : successor(tree, root, key); ++query_index; checksum += query_index * (answer + 1); }
    }
    return checksum;
}
