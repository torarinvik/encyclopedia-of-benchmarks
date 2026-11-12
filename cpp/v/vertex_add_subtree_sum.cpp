#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_n = 128;
constexpr std::size_t max_q = 256;
constexpr std::size_t max_input_values = 2 * max_n + 1 + 3 * max_q;
constexpr std::int64_t max_value = 1'000'000;

void add(std::array<std::int64_t, max_n + 1>& tree, std::size_t n,
         std::size_t position, std::int64_t delta) noexcept {
    for (auto index = position + 1; index <= n; index += index & (~index + 1))
        tree[index] += delta;
}

std::int64_t prefix(const std::array<std::int64_t, max_n + 1>& tree,
                    std::size_t count) noexcept {
    std::int64_t total = 0;
    for (auto index = count; index > 0; index -= index & (~index + 1))
        total += tree[index];
    return total;
}

void put_i64_le(std::uint8_t* output, std::size_t offset, std::int64_t value) noexcept {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
} // namespace

extern "C" std::int64_t vertex_add_subtree_sum(const std::int64_t* input,
    std::size_t length, std::uint8_t* output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 2 || length > max_input_values) return -1;
    const auto n_value = input[0], q_value = input[1];
    if (n_value < 1 || n_value > static_cast<std::int64_t>(max_n) ||
        q_value < 0 || q_value > static_cast<std::int64_t>(max_q)) return -1;
    const auto n = static_cast<std::size_t>(n_value), q = static_cast<std::size_t>(q_value);
    if (length != 2 * n + 1 + 3 * q) return -1;

    std::array<std::int64_t, max_n> values{}, first_child{}, next_sibling{};
    first_child.fill(-1);
    next_sibling.fill(-1);
    for (std::size_t vertex = 0; vertex < n; ++vertex) {
        values[vertex] = input[2 + vertex];
        if (values[vertex] < 0 || values[vertex] > max_value) return -1;
    }
    const auto parent_start = 2 + n;
    for (std::size_t vertex = 1; vertex < n; ++vertex) {
        const auto parent_value = input[parent_start + vertex - 1];
        if (parent_value < 0 || static_cast<std::size_t>(parent_value) >= vertex) return -1;
        const auto parent = static_cast<std::size_t>(parent_value);
        next_sibling[vertex] = first_child[parent];
        first_child[parent] = static_cast<std::int64_t>(vertex);
    }

    std::array<std::size_t, max_n> tin{}, tout{}, stack_node{};
    std::array<std::int64_t, max_n> stack_next_child{};
    std::size_t timer = 0, top = 1;
    stack_node[0] = 0;
    stack_next_child[0] = first_child[0];
    tin[0] = timer++;
    while (top > 0) {
        const auto frame = top - 1;
        const auto child_value = stack_next_child[frame];
        if (child_value < 0) {
            tout[stack_node[frame]] = timer;
            --top;
            continue;
        }
        const auto child = static_cast<std::size_t>(child_value);
        stack_next_child[frame] = next_sibling[child];
        tin[child] = timer++;
        stack_node[top] = child;
        stack_next_child[top] = first_child[child];
        ++top;
    }

    std::array<std::int64_t, max_n + 1> fenwick{};
    for (std::size_t vertex = 0; vertex < n; ++vertex)
        add(fenwick, n, tin[vertex], values[vertex]);

    std::array<std::int64_t, max_q> answers{};
    std::size_t answer_count = 0;
    const auto operation_start = parent_start + n - 1;
    for (std::size_t index = 0; index < q; ++index) {
        const auto offset = operation_start + 3 * index;
        const auto kind = input[offset], vertex_value = input[offset + 1];
        const auto operand = input[offset + 2];
        if (kind == 0) {
            if (vertex_value < 0 || static_cast<std::size_t>(vertex_value) >= n ||
                operand < 0 || operand > max_value) return -1;
            const auto vertex = static_cast<std::size_t>(vertex_value);
            values[vertex] += operand;
            add(fenwick, n, tin[vertex], operand);
        } else if (kind == 1) {
            if (vertex_value < 0 || static_cast<std::size_t>(vertex_value) >= n || operand != 0) return -1;
            const auto vertex = static_cast<std::size_t>(vertex_value);
            answers[answer_count++] = prefix(fenwick, tout[vertex]) - prefix(fenwick, tin[vertex]);
        } else return -1;
    }

    const auto output_bytes = 8 * answer_count;
    if (output_bytes > 0 && (output == nullptr || capacity < output_bytes)) return -2;
    for (std::size_t index = 0; index < answer_count; ++index)
        put_i64_le(output, 8 * index, answers[index]);
    return static_cast<std::int64_t>(output_bytes);
}
