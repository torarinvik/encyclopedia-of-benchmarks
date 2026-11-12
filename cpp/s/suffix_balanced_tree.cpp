#include <algorithm>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_text = 32, max_input = 33;
constexpr std::uint64_t tag_limit = UINT64_C(1) << 62;
struct Tree {
    std::int64_t text[max_text]{};
    int left[max_text]{}, right[max_text]{}, size[max_text]{};
    std::uint64_t tag[max_text]{};
    int buffer[max_text]{};
    int buffered = 0;
};
int node_size(const Tree& tree, int node) { return node < 0 ? 0 : tree.size[node]; }
bool suffix_less(const Tree& tree, int x, int y, int n) {
    if (tree.text[x] != tree.text[y]) return tree.text[x] < tree.text[y];
    const auto next_x = x + 1 < n ? tree.tag[x + 1] : 0;
    const auto next_y = y + 1 < n ? tree.tag[y + 1] : 0;
    return next_x < next_y;
}
void flatten(Tree& tree, int root) {
    if (root < 0) return;
    flatten(tree, tree.left[root]);
    tree.buffer[tree.buffered++] = root;
    flatten(tree, tree.right[root]);
}
int build_balanced(Tree& tree, int lo, int hi, std::uint64_t low, std::uint64_t high) {
    if (lo >= hi) return -1;
    const int mid = lo + (hi - lo) / 2;
    const int root = tree.buffer[mid];
    const auto tag = low + (high - low) / 2;
    tree.tag[root] = tag;
    tree.left[root] = build_balanced(tree, lo, mid, low, tag);
    tree.right[root] = build_balanced(tree, mid + 1, hi, tag, high);
    tree.size[root] = 1 + node_size(tree, tree.left[root]) + node_size(tree, tree.right[root]);
    return root;
}
int rebuild(Tree& tree, int root, std::uint64_t low, std::uint64_t high) {
    tree.buffered = 0; flatten(tree, root);
    return build_balanced(tree, 0, tree.buffered, low, high);
}
int insert_suffix(Tree& tree, int root, int pos, int n, std::uint64_t low, std::uint64_t high) {
    if (root < 0) {
        tree.left[pos] = tree.right[pos] = -1;
        tree.size[pos] = 1;
        tree.tag[pos] = low + (high - low) / 2;
        return pos;
    }
    const auto middle = tree.tag[root];
    if (suffix_less(tree, pos, root, n)) tree.left[root] = insert_suffix(tree, tree.left[root], pos, n, low, middle);
    else tree.right[root] = insert_suffix(tree, tree.right[root], pos, n, middle, high);
    const int ls = node_size(tree, tree.left[root]), rs = node_size(tree, tree.right[root]);
    tree.size[root] = 1 + ls + rs;
    if (4 * std::max(ls, rs) >= 3 * tree.size[root]) return rebuild(tree, root, low, high);
    return root;
}
void inorder(const Tree& tree, int root, std::int64_t answer[max_text], std::size_t& count) {
    if (root < 0) return;
    inorder(tree, tree.left[root], answer, count);
    answer[count++] = root;
    inorder(tree, tree.right[root], answer, count);
}
void store_le(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t suffix_balanced_tree(const std::int64_t* input, std::size_t length,
                                               std::uint8_t* output, std::size_t capacity) {
    if (!input || length < 1 || length > max_input) return -1;
    const auto nv = input[0];
    if (nv < 0 || nv > static_cast<std::int64_t>(max_text) || length != 1 + static_cast<std::size_t>(nv)) return -1;
    const int n = static_cast<int>(nv);
    for (int i = 0; i < n; ++i) if (input[1 + i] < 0 || input[1 + i] > 255) return -1;
    const auto required = 8 * static_cast<std::size_t>(n);
    if (!output || capacity < required) return -2;
    Tree tree{};
    for (int i = 0; i < n; ++i) tree.text[i] = input[1 + i];
    int root = -1;
    for (int pos = n - 1; pos >= 0; --pos) root = insert_suffix(tree, root, pos, n, 0, tag_limit);
    std::int64_t answer[max_text]{}; std::size_t count = 0;
    inorder(tree, root, answer, count);
    for (std::size_t i = 0; i < count; ++i) store_le(output, 8 * i, answer[i]);
    return static_cast<std::int64_t>(required);
}
