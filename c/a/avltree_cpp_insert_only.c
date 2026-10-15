/* Insert unique keys into an AVL tree and emit its keys in sorted order. */
#include <stddef.h>
#include <stdint.h>

#define MAX_NODES 256

static int avl_height(int root, const int left[MAX_NODES], const int right[MAX_NODES])
{
    if (root < 0) return 0;
    const int left_height = avl_height(left[root], left, right);
    const int right_height = avl_height(right[root], left, right);
    return 1 + (left_height > right_height ? left_height : right_height);
}

static int avl_balance(int root, const int left[MAX_NODES], const int right[MAX_NODES])
{
    return avl_height(left[root], left, right) - avl_height(right[root], left, right);
}

static int rotate_right(int root, int left[MAX_NODES], int right[MAX_NODES])
{
    const int pivot = left[root];
    const int moved = right[pivot];
    right[pivot] = root;
    left[root] = moved;
    return pivot;
}

static int rotate_left(int root, int left[MAX_NODES], int right[MAX_NODES])
{
    const int pivot = right[root];
    const int moved = left[pivot];
    left[pivot] = root;
    right[root] = moved;
    return pivot;
}

static int insert_node(int root, int32_t key, int32_t keys[MAX_NODES],
                       int left[MAX_NODES], int right[MAX_NODES], int *next_node)
{
    if (root < 0) {
        const int node = (*next_node)++;
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

static void store_i32_le(int32_t value, uint8_t *output, size_t offset)
{
    const uint32_t bits = (uint32_t)value;
    for (size_t byte = 0; byte < 4; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

static void emit_inorder(int root, const int32_t keys[MAX_NODES],
                         const int left[MAX_NODES], const int right[MAX_NODES],
                         uint8_t *output, size_t *position)
{
    if (root < 0) return;
    emit_inorder(left[root], keys, left, right, output, position);
    store_i32_le(keys[root], output, (*position)++ * 4);
    emit_inorder(right[root], keys, left, right, output, position);
}

int64_t avltree_cpp_insert_only(const int64_t *input, size_t length,
                                uint8_t *output, size_t output_capacity)
{
    if (input == NULL || length < 2 || length > MAX_NODES + 1) return -1;
    if (input[0] < 1 || input[0] > MAX_NODES) return -1;
    const size_t count = (size_t)input[0];
    if (length != count + 1) return -1;
    for (size_t index = 0; index < count; ++index) {
        const int64_t key = input[index + 1];
        if (key < INT32_MIN || key > INT32_MAX) return -1;
        for (size_t previous = 0; previous < index; ++previous)
            if (input[previous + 1] == key) return -1;
    }
    const size_t required = count * 4;
    if (output == NULL || output_capacity < required) return -2;

    int32_t keys[MAX_NODES];
    int left[MAX_NODES], right[MAX_NODES];
    for (size_t index = 0; index < count; ++index) {
        left[index] = -1;
        right[index] = -1;
    }
    int next_node = 0;
    int root = -1;
    for (size_t index = 0; index < count; ++index)
        root = insert_node(root, (int32_t)input[index + 1], keys, left, right, &next_node);

    size_t position = 0;
    emit_inorder(root, keys, left, right, output, &position);
    return (int64_t)position;
}
