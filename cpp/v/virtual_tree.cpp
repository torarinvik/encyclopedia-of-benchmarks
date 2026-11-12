/* Build a bounded LCA-closed virtual tree in DFS order. */
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_n = 32, max_virtual = 32, max_candidates = 64;
constexpr std::size_t max_words = 1 + 3 * max_virtual;
void put_word(std::uint8_t *out, std::size_t offset, std::int64_t value) noexcept {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t b = 0; b < 8; ++b) out[offset + b] = static_cast<std::uint8_t>(bits >> (8 * b));
}
std::size_t lca(std::size_t a, std::size_t b, const std::array<std::size_t, max_n>& parent,
                const std::array<std::size_t, max_n>& depth) noexcept {
    while (depth[a] > depth[b]) a = parent[a];
    while (depth[b] > depth[a]) b = parent[b];
    while (a != b) { a = parent[a]; b = parent[b]; }
    return a;
}
bool ancestor(std::size_t a, std::size_t b, const std::array<std::size_t, max_n>& tin,
              const std::array<std::size_t, max_n>& tout) noexcept {
    return tin[a] <= tin[b] && tin[b] < tout[a];
}
}

extern "C" std::int64_t virtual_tree(const std::int64_t *input, std::size_t length,
                                     std::uint8_t *output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 2 || length > 66 || input[0] < 1 || input[0] > 32 ||
        input[1] < 0 || input[1] > 32 || input[1] > input[0]) return -1;
    const auto n = static_cast<std::size_t>(input[0]), k = static_cast<std::size_t>(input[1]);
    if (length != n + k + 1) return -1;
    std::array<std::size_t, max_n> parent{}, depth{}, child_count{}, tin{}, tout{};
    std::array<std::array<std::size_t, max_n>, max_n> children{};
    for (std::size_t v = 1; v < n; ++v) {
        const auto p = input[v + 1];
        if (p < 0 || static_cast<std::uint64_t>(p) >= n || static_cast<std::size_t>(p) == v) return -1;
        parent[v] = static_cast<std::size_t>(p);
        children[parent[v]][child_count[parent[v]]++] = v;
    }
    std::array<std::size_t, max_n> marks{};
    for (std::size_t i = 0; i < k; ++i) {
        const auto value = input[n + 1 + i];
        if (value < 0 || static_cast<std::uint64_t>(value) >= n) return -1;
        marks[i] = static_cast<std::size_t>(value);
        for (std::size_t j = 0; j < i; ++j) if (marks[j] == marks[i]) return -1;
    }
    tin.fill(max_n); tout.fill(max_n);
    std::array<std::size_t, max_n> node_stack{}, next_stack{};
    std::size_t timer = 0, top = 1, reached = 1;
    node_stack[0] = 0; tin[0] = timer++;
    while (top != 0) {
        const auto frame = top - 1, vertex = node_stack[frame];
        if (next_stack[frame] == child_count[vertex]) { tout[vertex] = timer; --top; continue; }
        const auto child = children[vertex][next_stack[frame]++];
        if (tin[child] != max_n) return -1;
        tin[child] = timer++; depth[child] = depth[vertex] + 1; ++reached;
        node_stack[top] = child; next_stack[top] = 0; ++top;
    }
    if (reached != n) return -1;
    std::array<std::int64_t, max_words> words{};
    std::size_t word_count = 1;
    if (k == 0) words[0] = 0;
    else {
        for (std::size_t i = 1; i < k; ++i) {
            const auto value = marks[i]; std::size_t j = i;
            while (j != 0 && tin[marks[j - 1]] > tin[value]) { marks[j] = marks[j - 1]; --j; }
            marks[j] = value;
        }
        std::array<std::size_t, max_candidates> nodes{};
        std::array<std::size_t, max_virtual> unique{}, stack{};
        std::size_t count = 0;
        nodes[count++] = 0;
        for (std::size_t i = 0; i < k; ++i) nodes[count++] = marks[i];
        for (std::size_t i = 1; i < k; ++i) nodes[count++] = lca(marks[i - 1], marks[i], parent, depth);
        for (std::size_t i = 1; i < count; ++i) {
            const auto value = nodes[i]; std::size_t j = i;
            while (j != 0 && tin[nodes[j - 1]] > tin[value]) { nodes[j] = nodes[j - 1]; --j; }
            nodes[j] = value;
        }
        std::size_t unique_count = 0;
        for (std::size_t i = 0; i < count; ++i)
            if (unique_count == 0 || unique[unique_count - 1] != nodes[i]) unique[unique_count++] = nodes[i];
        words[0] = static_cast<std::int64_t>(unique_count);
        std::size_t stack_size = 0;
        for (std::size_t i = 0; i < unique_count; ++i) {
            const auto vertex = unique[i];
            while (stack_size != 0 && !ancestor(stack[stack_size - 1], vertex, tin, tout)) --stack_size;
            const auto vp = stack_size == 0 ? vertex : stack[stack_size - 1];
            words[word_count++] = static_cast<std::int64_t>(vertex);
            words[word_count++] = static_cast<std::int64_t>(vp);
            words[word_count++] = static_cast<std::int64_t>(depth[vertex] - depth[vp]);
            stack[stack_size++] = vertex;
        }
    }
    const auto bytes = word_count * 8;
    if (output == nullptr || capacity < bytes) return -2;
    for (std::size_t i = 0; i < word_count; ++i) put_word(output, i * 8, words[i]);
    return static_cast<std::int64_t>(bytes);
}
