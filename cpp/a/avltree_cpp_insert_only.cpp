/* Insert unique keys into an AVL tree and emit its keys in sorted order. */
#include <cstddef>
#include <cstdint>
#include <limits>

namespace {
constexpr std::size_t MAX_NODES = 256;

int avl_height(int root, const int left[MAX_NODES], const int right[MAX_NODES])
{
    if (root < 0) return 0;
    const int left_height = avl_height(left[root], left, right);
    const int right_height = avl_height(right[root], left, right);
    return 1 + (left_height > right_height ? left_height : right_height);
}

int avl_balance(int root, const int left[MAX_NODES], const int right[MAX_NODES])
{
    return avl_height(left[root], left, right) - avl_height(right[root], left, right);
}

int rotate_right(int root, int left[MAX_NODES], int right[MAX_NODES])
{
    const int pivot = left[root];
    const int moved = right[pivot];
    right[pivot] = root;
    left[root] = moved;
    return pivot;
}

int rotate_left(int root, int left[MAX_NODES], int right[MAX_NODES])
{
    const int pivot = right[root];
    const int moved = left[pivot];
    left[pivot] = root;
    right[root] = moved;
    return pivot;
}

int insert_node(int root, std::int32_t key, std::int32_t keys[MAX_NODES],
                int left[MAX_NODES], int right[MAX_NODES], int &next_node)
{
    if (root < 0) {
        const int node = next_node++;
        keys[node] = key;
        left[node] = -1;
        right[node] = -1;
        return node;
    }
    if (key < keys[root])
        left[root] = insert_node(left[root], key, keys, left, right, next_node);
    else
        right[root] = insert_node(right[root], key, keys, left, right, next_node);

    const int balance = avl_balance(root, left, right);
    if (balance > 1) {
        if (avl_balance(left[root], left, right) < 0)
            left[root] = rotate_left(left[root], left, right);
        return rotate_right(root, left, right);
    }
    if (balance < -1) {
        if (avl_balance(right[root], left, right) > 0)
            right[root] = rotate_right(right[root], left, right);
        return rotate_left(root, left, right);
    }
    return root;
}

void store_i32_le(std::int32_t value, std::uint8_t *output, std::size_t offset)
{
    const std::uint32_t bits = static_cast<std::uint32_t>(value);
    for (std::size_t byte = 0; byte < 4; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}

void emit_inorder(int root, const std::int32_t keys[MAX_NODES],
                  const int left[MAX_NODES], const int right[MAX_NODES],
                  std::uint8_t *output, std::size_t &position)
{
    if (root < 0) return;
    emit_inorder(left[root], keys, left, right, output, position);
    store_i32_le(keys[root], output, position++ * 4);
    emit_inorder(right[root], keys, left, right, output, position);
}
}

extern "C" std::int64_t avltree_cpp_insert_only(const std::int64_t *input,
                                                 std::size_t length,
                                                 std::uint8_t *output,
                                                 std::size_t output_capacity) noexcept
{
    if (input == nullptr || length < 2 || length > MAX_NODES + 1) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(MAX_NODES)) return -1;
    const auto count = static_cast<std::size_t>(input[0]);
    if (length != count + 1) return -1;
    for (std::size_t index = 0; index < count; ++index) {
        const auto key = input[index + 1];
        if (key < std::numeric_limits<std::int32_t>::min() ||
            key > std::numeric_limits<std::int32_t>::max()) return -1;
        for (std::size_t previous = 0; previous < index; ++previous)
            if (input[previous + 1] == key) return -1;
    }
    const std::size_t required = count * 4;
    if (output == nullptr || output_capacity < required) return -2;

    std::int32_t keys[MAX_NODES];
    int left[MAX_NODES], right[MAX_NODES];
    for (std::size_t index = 0; index < count; ++index) {
        left[index] = -1;
        right[index] = -1;
    }
    int next_node = 0;
    int root = -1;
    for (std::size_t index = 0; index < count; ++index)
        root = insert_node(root, static_cast<std::int32_t>(input[index + 1]), keys,
                           left, right, next_node);

    std::size_t position = 0;
    emit_inorder(root, keys, left, right, output, position);
    return static_cast<std::int64_t>(position);
}
