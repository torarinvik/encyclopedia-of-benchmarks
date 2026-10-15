#include <stddef.h>
#include <stdint.h>

#define MAX_NODES 63
#define MAX_OUTPUT (6 * MAX_NODES + 1)

int64_t create_binary_tree_from_inorder_preorder(const int64_t *values, size_t length,
                                                   uint8_t *output, size_t output_capacity)
{
    if (values == NULL || length < 1 || values[0] < 0 || values[0] > MAX_NODES) return -1;
    const size_t count = (size_t)values[0];
    if (length != 1 + 2 * count) return -1;
    const int64_t *preorder = values + 1;
    const int64_t *inorder = values + 1 + count;
    for (size_t i = 0; i < count; ++i) {
        if (preorder[i] < INT32_MIN || preorder[i] > INT32_MAX || inorder[i] < INT32_MIN || inorder[i] > INT32_MAX) return -1;
        for (size_t j = 0; j < i; ++j)
            if (preorder[i] == preorder[j] || inorder[i] == inorder[j]) return -1;
        size_t matches = 0;
        for (size_t j = 0; j < count; ++j) if (preorder[i] == inorder[j]) ++matches;
        if (matches != 1) return -1;
    }
    int left_child[MAX_NODES], right_child[MAX_NODES];
    for (size_t i = 0; i < count; ++i) left_child[i] = right_child[i] = -1;
    int task_pre[MAX_NODES], task_in[MAX_NODES], task_size[MAX_NODES];
    size_t tasks = 0;
    if (count > 0) { task_pre[tasks] = 0; task_in[tasks] = 0; task_size[tasks++] = (int)count; }
    while (tasks > 0) {
        --tasks;
        const int pre_start = task_pre[tasks], in_start = task_in[tasks], size = task_size[tasks];
        if (size <= 0 || pre_start < 0 || in_start < 0 || (size_t)(pre_start + size) > count || (size_t)(in_start + size) > count) return -1;
        int root_position = -1;
        for (int i = in_start; i < in_start + size; ++i)
            if (inorder[i] == preorder[pre_start]) { root_position = i; break; }
        if (root_position < 0) return -1;
        const int left_size = root_position - in_start;
        const int right_size = size - left_size - 1;
        if (left_size > 0) left_child[pre_start] = pre_start + 1;
        if (right_size > 0) right_child[pre_start] = pre_start + left_size + 1;
        if (right_size > 0) { task_pre[tasks] = pre_start + left_size + 1; task_in[tasks] = root_position + 1; task_size[tasks++] = right_size; }
        if (left_size > 0) { task_pre[tasks] = pre_start + 1; task_in[tasks] = in_start; task_size[tasks++] = left_size; }
    }
    const size_t required = 6 * count + 1;
    if (output == NULL || output_capacity < required) return -2;
    uint8_t encoded[MAX_OUTPUT];
    int pending[2 * MAX_NODES + 1];
    size_t top = 0, written = 0;
    pending[top++] = count == 0 ? -1 : 0;
    while (top > 0) {
        const int node = pending[--top];
        if (node < 0) { encoded[written++] = 0; continue; }
        const uint32_t value = (uint32_t)(int32_t)preorder[node];
        encoded[written++] = 1;
        for (unsigned byte = 0; byte < 4; ++byte) encoded[written++] = (uint8_t)(value >> (8 * byte));
        pending[top++] = right_child[node];
        pending[top++] = left_child[node];
    }
    for (size_t i = 0; i < written; ++i) output[i] = encoded[i];
    return (int64_t)count;
}
