// Breadth-first structural and value comparison of two indexed binary trees.
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_node_count = 1023;

struct TreeView {
    std::size_t count;
    std::int64_t root;
    const std::int64_t *rows;
};

bool parse_tree(const std::int64_t *input, std::size_t length, std::size_t &offset, TreeView &tree) {
    if (offset > length || length - offset < 2) return false;
    const auto count_value = input[offset];
    const auto root = input[offset + 1];
    if (count_value < 0 || count_value > static_cast<std::int64_t>(max_node_count)) return false;
    const auto count = static_cast<std::size_t>(count_value);
    const auto row_start = offset + 2;
    if (count > (length - row_start) / 3) return false;
    tree = TreeView{count, root, input + row_start};
    offset = row_start + 3 * count;
    return true;
}

bool valid_tree(const TreeView &tree) {
    if (tree.count == 0) return tree.root == -1;
    if (tree.root < 0 || static_cast<std::uint64_t>(tree.root) >= tree.count) return false;
    std::size_t parents[max_node_count]{};
    for (std::size_t index = 0; index < tree.count; ++index) {
        const auto value = tree.rows[3 * index];
        const auto left = tree.rows[3 * index + 1];
        const auto right = tree.rows[3 * index + 2];
        if (value < INT32_MIN || value > INT32_MAX || left < -1 || right < -1 ||
            (left >= 0 && static_cast<std::uint64_t>(left) >= tree.count) ||
            (right >= 0 && static_cast<std::uint64_t>(right) >= tree.count)) return false;
        if (left >= 0 && ++parents[static_cast<std::size_t>(left)] > 1) return false;
        if (right >= 0 && ++parents[static_cast<std::size_t>(right)] > 1) return false;
    }
    for (std::size_t index = 0; index < tree.count; ++index) {
        if (parents[index] != (index == static_cast<std::size_t>(tree.root) ? 0U : 1U)) return false;
    }
    std::size_t queue[max_node_count], head = 0, tail = 0;
    bool seen[max_node_count]{};
    queue[tail++] = static_cast<std::size_t>(tree.root);
    while (head < tail) {
        const auto index = queue[head++];
        if (seen[index]) return false;
        seen[index] = true;
        const auto left = tree.rows[3 * index + 1];
        const auto right = tree.rows[3 * index + 2];
        if (left >= 0) queue[tail++] = static_cast<std::size_t>(left);
        if (right >= 0) queue[tail++] = static_cast<std::size_t>(right);
    }
    return tail == tree.count;
}

bool trees_equal(const TreeView &first, const TreeView &second) {
    if (first.root == -1 || second.root == -1) return first.root == second.root;
    std::int64_t queue1[max_node_count], queue2[max_node_count];
    std::size_t head = 0, tail = 0;
    queue1[tail] = first.root;
    queue2[tail++] = second.root;
    while (head < tail) {
        const auto index1 = static_cast<std::size_t>(queue1[head]);
        const auto index2 = static_cast<std::size_t>(queue2[head++]);
        const auto *a = first.rows + 3 * index1;
        const auto *b = second.rows + 3 * index2;
        if (a[0] != b[0] || (a[1] == -1) != (b[1] == -1) ||
            (a[2] == -1) != (b[2] == -1)) return false;
        if (a[1] >= 0) { queue1[tail] = a[1]; queue2[tail++] = b[1]; }
        if (a[2] >= 0) { queue1[tail] = a[2]; queue2[tail++] = b[2]; }
    }
    return true;
}
}

extern "C" std::int64_t same_trees_check(const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length < 4) return -1;
    std::size_t offset = 0;
    TreeView first{}, second{};
    if (!parse_tree(input, length, offset, first) || !parse_tree(input, length, offset, second) ||
        offset != length || first.count + second.count > max_node_count ||
        !valid_tree(first) || !valid_tree(second)) return -1;
    return trees_equal(first, second) ? 1 : 0;
}
