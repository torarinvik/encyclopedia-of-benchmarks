#include <cstddef>
#include <cstdint>
#include <climits>

namespace {
constexpr std::size_t max_operations = 128;
constexpr std::int64_t invalid_result = -1;
constexpr std::int64_t capacity_result = -2;
struct Node { std::int64_t key = 0; std::size_t left = 0, right = 0; bool red = false; };

bool is_red(const Node *tree, std::size_t node) { return node != 0 && tree[node].red; }
void flip_colors(Node *tree, std::size_t node) {
    tree[node].red = !tree[node].red;
    tree[tree[node].left].red = !tree[tree[node].left].red;
    tree[tree[node].right].red = !tree[tree[node].right].red;
}
std::size_t rotate_left(Node *tree, std::size_t node) {
    const auto pivot = tree[node].right;
    tree[node].right = tree[pivot].left;
    tree[pivot].left = node;
    tree[pivot].red = tree[node].red;
    tree[node].red = true;
    return pivot;
}
std::size_t rotate_right(Node *tree, std::size_t node) {
    const auto pivot = tree[node].left;
    tree[node].left = tree[pivot].right;
    tree[pivot].right = node;
    tree[pivot].red = tree[node].red;
    tree[node].red = true;
    return pivot;
}
std::size_t insert_node(Node *tree, std::size_t node, std::int64_t key, std::size_t &next) {
    if (node == 0) { const auto created = next++; tree[created] = Node{key, 0, 0, true}; return created; }
    if (is_red(tree, tree[node].left) && is_red(tree, tree[node].right)) flip_colors(tree, node);
    if (key == tree[node].key) tree[node].key = key;
    else if (key < tree[node].key) tree[node].left = insert_node(tree, tree[node].left, key, next);
    else tree[node].right = insert_node(tree, tree[node].right, key, next);
    if (is_red(tree, tree[node].right) && !is_red(tree, tree[node].left)) node = rotate_left(tree, node);
    if (is_red(tree, tree[node].left) && is_red(tree, tree[tree[node].left].left)) node = rotate_right(tree, node);
    return node;
}
std::size_t find_node(const Node *tree, std::size_t node, std::int64_t key) {
    while (node != 0) {
        if (key < tree[node].key) node = tree[node].left;
        else if (key > tree[node].key) node = tree[node].right;
        else return node;
    }
    return 0;
}
void insertion_sort(std::int64_t *values, std::size_t count) {
    for (std::size_t index = 1; index < count; ++index) {
        const auto value = values[index]; auto position = index;
        while (position > 0 && values[position - 1] > value) { values[position] = values[position - 1]; --position; }
        values[position] = value;
    }
}
void write_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t red_black_tree_insert_search(const std::int64_t *input, std::size_t length,
                                                          std::uint8_t *output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 1) return invalid_result;
    if (input[0] < 0 || input[0] > static_cast<std::int64_t>(max_operations) || length != 1 + 2 * static_cast<std::size_t>(input[0])) return invalid_result;
    const auto operation_count = static_cast<std::size_t>(input[0]);
    for (std::size_t op = 0; op < operation_count; ++op) {
        const auto opcode = input[1 + 2 * op], key = input[2 + 2 * op];
        if ((opcode != 0 && opcode != 1) || key < INT32_MIN || key > INT32_MAX) return invalid_result;
    }
    Node tree[max_operations + 1]{};
    std::int64_t keys[max_operations]{}, search_results[max_operations]{};
    std::size_t root = 0, next = 1, key_count = 0, search_count = 0;
    for (std::size_t op = 0; op < operation_count; ++op) {
        const auto opcode = input[1 + 2 * op], key = input[2 + 2 * op];
        if (opcode == 0) {
            if (find_node(tree, root, key) != 0) return invalid_result;
            root = insert_node(tree, root, key, next);
            tree[root].red = false;
            keys[key_count++] = key;
        } else search_results[search_count++] = find_node(tree, root, key) != 0 ? 1 : 0;
    }
    insertion_sort(keys, key_count);
    const auto required = (2 + key_count + search_count) * 8;
    if (output == nullptr || capacity < required) return capacity_result;
    std::size_t offset = 0;
    write_i64_le(output, offset, static_cast<std::int64_t>(key_count)); offset += 8;
    for (std::size_t i = 0; i < key_count; ++i, offset += 8) write_i64_le(output, offset, keys[i]);
    write_i64_le(output, offset, static_cast<std::int64_t>(search_count)); offset += 8;
    for (std::size_t i = 0; i < search_count; ++i, offset += 8) write_i64_le(output, offset, search_results[i]);
    return static_cast<std::int64_t>(required);
}
