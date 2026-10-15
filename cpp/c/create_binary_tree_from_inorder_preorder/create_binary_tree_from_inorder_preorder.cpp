#include <cstddef>
#include <cstdint>
#include <vector>

namespace {
constexpr std::size_t max_nodes = 63;
constexpr std::size_t max_output = 6 * max_nodes + 1;
}

extern "C" std::int64_t create_binary_tree_from_inorder_preorder(const std::int64_t *values,
    std::size_t length, std::uint8_t *output, std::size_t output_capacity) {
    if (values == nullptr || length < 1 || values[0] < 0 || values[0] > max_nodes) return -1;
    const auto count = static_cast<std::size_t>(values[0]);
    if (length != 1 + 2 * count) return -1;
    const auto *preorder = values + 1;
    const auto *inorder = values + 1 + count;
    for (std::size_t i = 0; i < count; ++i) {
        if (preorder[i] < INT32_MIN || preorder[i] > INT32_MAX || inorder[i] < INT32_MIN || inorder[i] > INT32_MAX) return -1;
        for (std::size_t j = 0; j < i; ++j) if (preorder[i] == preorder[j] || inorder[i] == inorder[j]) return -1;
        std::size_t matches = 0;
        for (std::size_t j = 0; j < count; ++j) if (preorder[i] == inorder[j]) ++matches;
        if (matches != 1) return -1;
    }
    std::vector<int> left(count, -1), right(count, -1);
    struct Task { int pre; int in; int size; };
    std::vector<Task> tasks;
    if (count > 0) tasks.push_back({0, 0, static_cast<int>(count)});
    while (!tasks.empty()) {
        const auto task = tasks.back(); tasks.pop_back();
        if (task.size <= 0 || task.pre < 0 || task.in < 0 ||
            static_cast<std::size_t>(task.pre + task.size) > count || static_cast<std::size_t>(task.in + task.size) > count) return -1;
        int root_position = -1;
        for (int i = task.in; i < task.in + task.size; ++i)
            if (inorder[i] == preorder[task.pre]) { root_position = i; break; }
        if (root_position < 0) return -1;
        const int left_size = root_position - task.in;
        const int right_size = task.size - left_size - 1;
        if (left_size > 0) left[task.pre] = task.pre + 1;
        if (right_size > 0) right[task.pre] = task.pre + left_size + 1;
        if (right_size > 0) tasks.push_back({task.pre + left_size + 1, root_position + 1, right_size});
        if (left_size > 0) tasks.push_back({task.pre + 1, task.in, left_size});
    }
    const std::size_t required = 6 * count + 1;
    if (output == nullptr || output_capacity < required) return -2;
    std::vector<std::uint8_t> encoded;
    encoded.reserve(required);
    std::vector<int> pending{count == 0 ? -1 : 0};
    while (!pending.empty()) {
        const int node = pending.back(); pending.pop_back();
        if (node < 0) { encoded.push_back(0); continue; }
        const auto value = static_cast<std::uint32_t>(static_cast<std::int32_t>(preorder[node]));
        encoded.push_back(1);
        for (unsigned byte = 0; byte < 4; ++byte) encoded.push_back(static_cast<std::uint8_t>(value >> (8 * byte)));
        pending.push_back(right[node]); pending.push_back(left[node]);
    }
    for (std::size_t i = 0; i < encoded.size(); ++i) output[i] = encoded[i];
    return static_cast<std::int64_t>(count);
}
