#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_nodes = 64;
constexpr std::size_t max_input_length = 3 + 3 * max_nodes;

void walk(std::int64_t order, const std::int64_t *values, const std::int64_t *left,
          const std::int64_t *right, std::size_t node, std::int64_t *out, std::size_t &used) noexcept {
    if (order == 0) out[used++] = values[node];
    if (left[node] >= 0) walk(order, values, left, right, static_cast<std::size_t>(left[node]), out, used);
    if (order == 1) out[used++] = values[node];
    if (right[node] >= 0) walk(order, values, left, right, static_cast<std::size_t>(right[node]), out, used);
    if (order == 2) out[used++] = values[node];
}

void breadth_first(std::int64_t order, const std::int64_t *values, const std::int64_t *left,
                   const std::int64_t *right, std::size_t root, std::int64_t *out,
                   std::size_t &used) noexcept {
    std::size_t queue[max_nodes], head = 0, tail = 0;
    queue[tail++] = root;
    while (head < tail) {
        const auto node = queue[head++];
        out[used++] = values[node];
        const auto first = order == 3 ? left[node] : right[node];
        const auto second = order == 3 ? right[node] : left[node];
        if (first >= 0) queue[tail++] = static_cast<std::size_t>(first);
        if (second >= 0) queue[tail++] = static_cast<std::size_t>(second);
    }
}

void breadth_first_zigzag(const std::int64_t *values, const std::int64_t *left,
                          const std::int64_t *right, std::size_t root, std::int64_t *out,
                          std::size_t &used) noexcept {
    std::size_t queue[max_nodes], head = 0, tail = 0, level = 0;
    queue[tail++] = root;
    while (head < tail) {
        const auto level_end = tail, start = used;
        while (head < level_end) {
            const auto node = queue[head++];
            out[used++] = values[node];
            if (left[node] >= 0) queue[tail++] = static_cast<std::size_t>(left[node]);
            if (right[node] >= 0) queue[tail++] = static_cast<std::size_t>(right[node]);
        }
        if (level % 2 == 1) {
            std::size_t lo = start, hi = used;
            while (lo < hi) {
                --hi;
                if (lo >= hi) break;
                const auto value = out[lo]; out[lo++] = out[hi]; out[hi] = value;
            }
        }
        ++level;
    }
}

std::size_t mark_reachable(const std::int64_t *left, const std::int64_t *right,
                           std::size_t root, std::uint8_t *seen) noexcept {
    std::size_t stack[max_nodes], top = 0, count = 0;
    stack[top++] = root;
    while (top) {
        const auto node = stack[--top];
        if (seen[node]) continue;
        seen[node] = 1;
        ++count;
        if (right[node] >= 0) stack[top++] = static_cast<std::size_t>(right[node]);
        if (left[node] >= 0) stack[top++] = static_cast<std::size_t>(left[node]);
    }
    return count;
}

void put_i64(std::uint8_t *out, std::size_t index, std::int64_t value) noexcept {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) out[index * 8 + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t binary_tree_traversal(const std::int64_t *input,
                                                std::size_t length,
                                                std::uint8_t *output,
                                                std::size_t capacity) noexcept {
    if (!input || length < 3 || length > max_input_length) return -1;
    const auto order = input[0], count_value = input[1], root_value = input[2];
    if (order < 0 || order > 6 || count_value < 0 || count_value > static_cast<std::int64_t>(max_nodes) || length != 3 + 3 * static_cast<std::size_t>(count_value)) return -1;
    const auto n = static_cast<std::size_t>(count_value);
    if ((n == 0 && root_value != -1) || (n > 0 && (root_value < 0 || root_value >= static_cast<std::int64_t>(n)))) return -1;
    std::int64_t values[max_nodes]{}, left[max_nodes]{}, right[max_nodes]{};
    std::uint8_t parents[max_nodes]{};
    for (std::size_t i = 0; i < n; ++i) {
        values[i] = input[3 + 3 * i];
        left[i] = input[4 + 3 * i];
        right[i] = input[5 + 3 * i];
        if (left[i] < -1 || left[i] >= static_cast<std::int64_t>(n) || right[i] < -1 || right[i] >= static_cast<std::int64_t>(n) || left[i] == static_cast<std::int64_t>(i) || right[i] == static_cast<std::int64_t>(i)) return -1;
        if (left[i] >= 0 && ++parents[left[i]] > 1) return -1;
        if (right[i] >= 0 && ++parents[right[i]] > 1) return -1;
    }
    std::int64_t result[max_nodes];
    std::size_t used = 0;
    if (n) {
        const auto root = static_cast<std::size_t>(root_value);
        for (std::size_t i = 0; i < n; ++i) if (parents[i] != (i == root ? 0 : 1)) return -1;
        std::uint8_t seen[max_nodes]{};
        if (mark_reachable(left, right, root, seen) != n) return -1;
        if (order <= 2) walk(order, values, left, right, root, result, used);
        else if (order == 5) walk(1, values, right, left, root, result, used);
        else if (order == 6) breadth_first_zigzag(values, left, right, root, result, used);
        else breadth_first(order, values, left, right, root, result, used);
    }
    if (!output || capacity < used * 8) return -2;
    for (std::size_t i = 0; i < used; ++i) put_i64(output, i, result[i]);
    return static_cast<std::int64_t>(used * 8);
}
