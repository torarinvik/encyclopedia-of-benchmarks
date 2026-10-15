/* Fixed-capacity B-tree multiset with split-on-descent insertion. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MaxNodeCount = 257, MaxNodeKeys = 15, MaxNodeChildren = 16;
constexpr std::size_t MaxKeyCount = 256, MaxOperations = 511;
constexpr std::int64_t Offset = 1'000'000, HashMod = 1'000'000'007;

struct BTree {
    std::int64_t keys[MaxNodeCount][MaxNodeKeys]{};
    std::size_t children[MaxNodeCount][MaxNodeChildren]{};
    std::uint8_t key_count[MaxNodeCount]{};
    bool leaf[MaxNodeCount]{};
    std::size_t used_nodes = 1, root = 0, min_degree = 2;
};

bool split_child(BTree &tree, std::size_t parent, std::size_t child_index)
{
    if (tree.used_nodes >= MaxNodeCount) return false;
    const auto child = tree.children[parent][child_index];
    const auto degree = tree.min_degree;
    const auto sibling = tree.used_nodes++;
    tree.leaf[sibling] = tree.leaf[child];
    tree.key_count[sibling] = static_cast<std::uint8_t>(degree - 1);
    for (std::size_t i = 0; i < degree - 1; ++i)
        tree.keys[sibling][i] = tree.keys[child][degree + i];
    if (!tree.leaf[child])
        for (std::size_t i = 0; i < degree; ++i)
            tree.children[sibling][i] = tree.children[child][degree + i];

    const auto parent_count = tree.key_count[parent];
    for (std::size_t i = parent_count + 1; i > child_index + 1; --i)
        tree.children[parent][i] = tree.children[parent][i - 1];
    tree.children[parent][child_index + 1] = sibling;
    for (std::size_t i = parent_count; i > child_index; --i)
        tree.keys[parent][i] = tree.keys[parent][i - 1];
    tree.keys[parent][child_index] = tree.keys[child][degree - 1];
    tree.key_count[child] = static_cast<std::uint8_t>(degree - 1);
    tree.key_count[parent] = static_cast<std::uint8_t>(parent_count + 1);
    return true;
}

bool insert_non_full(BTree &tree, std::size_t node, std::int64_t key)
{
    std::size_t index = tree.key_count[node];
    if (tree.leaf[node]) {
        while (index > 0 && key <= tree.keys[node][index - 1]) {
            tree.keys[node][index] = tree.keys[node][index - 1];
            --index;
        }
        tree.keys[node][index] = key;
        ++tree.key_count[node];
        return true;
    }
    while (index > 0 && key <= tree.keys[node][index - 1]) --index;
    const auto child = tree.children[node][index];
    if (tree.key_count[child] == 2 * tree.min_degree - 1) {
        if (!split_child(tree, node, index)) return false;
        if (tree.keys[node][index] < key) ++index;
    }
    return insert_non_full(tree, tree.children[node][index], key);
}

bool insert_key(BTree &tree, std::int64_t key)
{
    if (tree.key_count[tree.root] == 2 * tree.min_degree - 1) {
        if (tree.used_nodes + 2 > MaxNodeCount) return false;
        const auto old_root = tree.root;
        const auto new_root = tree.used_nodes++;
        tree.leaf[new_root] = false;
        tree.key_count[new_root] = 0;
        tree.children[new_root][0] = old_root;
        tree.root = new_root;
        if (!split_child(tree, new_root, 0)) return false;
    }
    return insert_non_full(tree, tree.root, key);
}

bool search_key(const BTree &tree, std::int64_t key)
{
    auto node = tree.root;
    for (;;) {
        std::size_t index = 0;
        while (index < tree.key_count[node] && key > tree.keys[node][index]) ++index;
        if (index < tree.key_count[node] && key == tree.keys[node][index]) return true;
        if (tree.leaf[node]) return false;
        node = tree.children[node][index];
    }
}

std::int64_t walk_in_order(const BTree &tree, std::size_t operation_count,
                           std::int64_t *ordered_sum)
{
    std::size_t node_stack[32]{}, position_stack[32]{}, depth = 1, index = 0;
    std::int64_t hash = 0;
    node_stack[0] = tree.root;
    while (depth > 0) {
        const auto top = depth - 1;
        const auto node = node_stack[top];
        const auto count = tree.key_count[node];
        if (tree.leaf[node]) {
            if (position_stack[top] == count) { --depth; continue; }
            const auto value = tree.keys[node][position_stack[top]++];
            hash = (hash * 257 + value + 1'000'001) % HashMod;
            if (ordered_sum != nullptr)
                *ordered_sum += static_cast<std::int64_t>(operation_count + index + 1) * (value + Offset);
            ++index;
        } else if (position_stack[top] > 2 * count) {
            --depth;
        } else {
            const auto position = position_stack[top]++;
            if (position % 2 == 0) {
                node_stack[depth] = tree.children[node][position / 2];
                position_stack[depth] = 0;
                ++depth;
            } else {
                const auto value = tree.keys[node][position / 2];
                hash = (hash * 257 + value + 1'000'001) % HashMod;
                if (ordered_sum != nullptr)
                    *ordered_sum += static_cast<std::int64_t>(operation_count + index + 1) * (value + Offset);
                ++index;
            }
        }
    }
    return hash;
}
} // namespace

extern "C" std::int64_t b_tree_benchmark(const std::int64_t *values, std::size_t length) noexcept
{
    if (values == nullptr || length < 2 || length > 1024 || values[0] < 2 || values[0] > 8 ||
        values[1] < 0 || values[1] > static_cast<std::int64_t>(MaxOperations)) return -1;
    const auto operation_count = static_cast<std::size_t>(values[1]);
    if (length != 2 + 2 * operation_count) return -1;
    BTree tree{};
    tree.min_degree = static_cast<std::size_t>(values[0]);
    tree.leaf[tree.root] = true;
    std::size_t key_count = 0;
    std::int64_t checksum = 0;
    for (std::size_t operation = 0; operation < operation_count; ++operation) {
        const auto opcode = values[2 + 2 * operation], payload = values[3 + 2 * operation];
        std::int64_t observed = 0;
        if (opcode == 0) {
            if (payload < -Offset || payload > Offset || key_count == MaxKeyCount || !insert_key(tree, payload)) return -1;
            ++key_count;
            observed = 1;
        } else if (opcode == 1) {
            if (payload < -Offset || payload > Offset) return -1;
            observed = search_key(tree, payload) ? 1 : 0;
        } else if (opcode == 2) {
            if (payload != 0) return -1;
            observed = walk_in_order(tree, 0, nullptr);
        } else return -1;
        checksum += static_cast<std::int64_t>(operation + 1) * (observed + Offset);
    }
    walk_in_order(tree, operation_count, &checksum);
    return checksum;
}
