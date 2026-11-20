#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_tree_nodes = 15;
constexpr std::size_t max_total_nodes = 30;
constexpr std::size_t max_parseable_length = 93;

bool valid_tree(const std::int64_t* input, std::size_t offset, std::size_t node_count) noexcept {
    std::int64_t visited[max_tree_nodes]{};
    std::int64_t parents[max_tree_nodes]{};
    std::size_t stack[max_tree_nodes]{};
    std::size_t top = 1;
    std::size_t reached = 0;
    while (top > 0) {
        const auto node = stack[--top];
        if (node >= node_count || visited[node] != 0) return false;
        visited[node] = 1;
        ++reached;
        const auto base = offset + 3 * node;
        const auto left = input[base + 1];
        const auto right = input[base + 2];
        if (left == -1 && right == -1) continue;
        if (left < 0 || right < 0 || static_cast<std::uint64_t>(left) >= node_count ||
            static_cast<std::uint64_t>(right) >= node_count || left == right || left == 0 || right == 0) return false;
        if (++parents[static_cast<std::size_t>(left)] != 1 ||
            ++parents[static_cast<std::size_t>(right)] != 1) return false;
        stack[top++] = static_cast<std::size_t>(right);
        stack[top++] = static_cast<std::size_t>(left);
    }
    if (reached != node_count || parents[0] != 0) return false;
    for (std::size_t node = 1; node < node_count; ++node)
        if (parents[node] != 1) return false;
    return true;
}
}

extern "C" std::int64_t same_fringe_leaf_iterator(const std::int64_t* input,
                                                   std::size_t length) noexcept {
    if (input == nullptr || length < 2 || length > max_parseable_length) return -1;
    const auto n_a_word = input[0];
    const auto n_b_word = input[1];
    if (n_a_word < 1 || n_a_word > static_cast<std::int64_t>(max_tree_nodes) ||
        n_b_word < 1 || n_b_word > static_cast<std::int64_t>(max_tree_nodes)) return -1;
    const auto n_a = static_cast<std::size_t>(n_a_word);
    const auto n_b = static_cast<std::size_t>(n_b_word);
    if (n_a + n_b > max_total_nodes || length != 2 + 3 * (n_a + n_b)) return -1;
    const std::size_t offset_a = 2;
    const std::size_t offset_b = 2 + 3 * n_a;
    if (!valid_tree(input, offset_a, n_a) || !valid_tree(input, offset_b, n_b)) return -1;

    std::size_t stack_a[max_tree_nodes]{};
    std::size_t stack_b[max_tree_nodes]{};
    std::size_t top_a = 1;
    std::size_t top_b = 1;
    while (true) {
        bool have_a = false;
        bool have_b = false;
        std::int64_t leaf_a = 0;
        std::int64_t leaf_b = 0;
        while (top_a > 0 && !have_a) {
            const auto node = stack_a[--top_a];
            const auto base = offset_a + 3 * node;
            const auto left = input[base + 1];
            const auto right = input[base + 2];
            if (left == -1) {
                leaf_a = input[base];
                have_a = true;
            } else {
                stack_a[top_a++] = static_cast<std::size_t>(right);
                stack_a[top_a++] = static_cast<std::size_t>(left);
            }
        }
        while (top_b > 0 && !have_b) {
            const auto node = stack_b[--top_b];
            const auto base = offset_b + 3 * node;
            const auto left = input[base + 1];
            const auto right = input[base + 2];
            if (left == -1) {
                leaf_b = input[base];
                have_b = true;
            } else {
                stack_b[top_b++] = static_cast<std::size_t>(right);
                stack_b[top_b++] = static_cast<std::size_t>(left);
            }
        }
        if (!have_a || !have_b) return have_a == have_b ? 1 : 0;
        if (leaf_a != leaf_b) return 0;
    }
    return -1;
}
