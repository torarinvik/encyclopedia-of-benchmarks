#include <cstdint>

namespace {
constexpr std::int32_t max_level = 12;
constexpr std::int32_t max_nodes = (1 << max_level) - 1;
constexpr std::int32_t addition_passes = 100;

struct Node {
    std::int32_t value;
    std::int32_t left;
    std::int32_t right;
};

std::int32_t allocate_tree(Node *nodes, std::int32_t &used,
                           std::int32_t level, std::int32_t lo, std::int32_t proc) {
    if (level == 0 || used >= max_nodes) return -1;
    const std::int32_t index = used++;
    nodes[index].value = 1;
    const std::int32_t left = allocate_tree(nodes, used, level - 1, lo + proc / 2, proc / 2);
    const std::int32_t right = allocate_tree(nodes, used, level - 1, lo, proc / 2);
    nodes[index].left = left;
    nodes[index].right = right;
    return index;
}

std::int64_t tree_add(const Node *nodes, std::int32_t index) {
    if (index < 0) return 0;
    return nodes[index].value + tree_add(nodes, nodes[index].left) +
           tree_add(nodes, nodes[index].right);
}
}

extern "C" std::int64_t treeadd(std::int64_t level) {
    if (level < 0 || level > max_level) return -1;
    Node nodes[max_nodes];
    std::int32_t used = 0;
    const std::int32_t root = allocate_tree(nodes, used, static_cast<std::int32_t>(level), 0, 4);
    std::int64_t result = 0;
    for (std::int32_t pass = 0; pass < addition_passes; ++pass) {
        result = tree_add(nodes, root);
    }
    return result;
}
