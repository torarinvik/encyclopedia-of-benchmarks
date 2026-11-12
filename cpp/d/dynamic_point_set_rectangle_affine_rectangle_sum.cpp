#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_n = 32, max_q = 32, max_points = max_n + max_q;
constexpr std::size_t max_tree = 4 * max_points + 8;
constexpr std::size_t max_parseable_input = 2 + 3 * max_n + 7 * max_q + 1;
constexpr std::int64_t mod = 998244353, max_coord = 1'000'000'000;

struct Operation { std::int64_t kind, a, b, c, d, e, f; };
struct Node {
    std::int64_t min_x = 0, max_x = 0, min_y = 0, max_y = 0;
    std::int64_t sum = 0, lazy_a = 1, lazy_b = 0;
    std::size_t active = 0;
};

bool point_less(std::size_t left, std::size_t right,
                const std::array<std::int64_t, max_points>& xs,
                const std::array<std::int64_t, max_points>& ys,
                std::size_t axis) {
    const auto first = axis == 0 ? xs[left] : ys[left];
    const auto second = axis == 0 ? xs[right] : ys[right];
    if (first != second) return first < second;
    const auto first_other = axis == 0 ? ys[left] : xs[left];
    const auto second_other = axis == 0 ? ys[right] : xs[right];
    if (first_other != second_other) return first_other < second_other;
    return left < right;
}

void sort_points(std::array<std::size_t, max_points>& order,
                 const std::array<std::int64_t, max_points>& xs,
                 const std::array<std::int64_t, max_points>& ys,
                 std::size_t low, std::size_t high, std::size_t axis) {
    for (std::size_t i = low + 1; i < high; ++i) {
        const auto point = order[i];
        auto j = i;
        while (j > low && point_less(point, order[j - 1], xs, ys, axis)) {
            order[j] = order[j - 1];
            --j;
        }
        order[j] = point;
    }
}

void build_tree(std::array<Node, max_tree>& tree,
                std::array<std::size_t, max_points>& order,
                const std::array<std::int64_t, max_points>& xs,
                const std::array<std::int64_t, max_points>& ys,
                const std::array<std::int64_t, max_points>& weights,
                std::array<std::size_t, max_points>& rank,
                std::size_t low, std::size_t high, std::size_t index,
                std::size_t depth, std::size_t initial_n) {
    auto& node = tree[index];
    node.lazy_a = 1;
    if (high - low == 1) {
        const auto point = order[low];
        node.min_x = node.max_x = xs[point];
        node.min_y = node.max_y = ys[point];
        node.active = point < initial_n ? 1 : 0;
        node.sum = point < initial_n ? weights[point] : 0;
        rank[point] = low;
        return;
    }
    sort_points(order, xs, ys, low, high, depth & 1);
    const auto middle = low + (high - low) / 2;
    build_tree(tree, order, xs, ys, weights, rank, low, middle, index * 2, depth + 1, initial_n);
    build_tree(tree, order, xs, ys, weights, rank, middle, high, index * 2 + 1, depth + 1, initial_n);
    const auto& left = tree[index * 2];
    const auto& right = tree[index * 2 + 1];
    node.min_x = left.min_x < right.min_x ? left.min_x : right.min_x;
    node.max_x = left.max_x > right.max_x ? left.max_x : right.max_x;
    node.min_y = left.min_y < right.min_y ? left.min_y : right.min_y;
    node.max_y = left.max_y > right.max_y ? left.max_y : right.max_y;
    node.active = left.active + right.active;
    node.sum = (left.sum + right.sum) % mod;
}

void apply_node(std::array<Node, max_tree>& tree, std::size_t index,
                std::int64_t a, std::int64_t b) {
    auto& node = tree[index];
    if (node.active == 0) return;
    node.sum = (a * node.sum + b * static_cast<std::int64_t>(node.active)) % mod;
    node.lazy_a = a * node.lazy_a % mod;
    node.lazy_b = (a * node.lazy_b + b) % mod;
}

void push(std::array<Node, max_tree>& tree, std::size_t index,
          std::size_t low, std::size_t high) {
    auto& node = tree[index];
    if (high - low == 1 || (node.lazy_a == 1 && node.lazy_b == 0)) return;
    apply_node(tree, index * 2, node.lazy_a, node.lazy_b);
    apply_node(tree, index * 2 + 1, node.lazy_a, node.lazy_b);
    node.lazy_a = 1;
    node.lazy_b = 0;
}

bool disjoint(const Node& node, std::int64_t left, std::int64_t down,
              std::int64_t right, std::int64_t up) {
    return node.max_x < left || node.min_x >= right ||
           node.max_y < down || node.min_y >= up;
}
bool covered(const Node& node, std::int64_t left, std::int64_t down,
             std::int64_t right, std::int64_t up) {
    return left <= node.min_x && node.max_x < right &&
           down <= node.min_y && node.max_y < up;
}
void pull(std::array<Node, max_tree>& tree, std::size_t index) {
    auto& node = tree[index];
    const auto& left = tree[index * 2];
    const auto& right = tree[index * 2 + 1];
    node.sum = (left.sum + right.sum) % mod;
    node.active = left.active + right.active;
}

std::int64_t rectangle_sum(std::array<Node, max_tree>& tree, std::size_t index,
        std::size_t low, std::size_t high, std::int64_t left, std::int64_t down,
        std::int64_t right, std::int64_t up) {
    auto& node = tree[index];
    if (node.active == 0 || disjoint(node, left, down, right, up)) return 0;
    if (covered(node, left, down, right, up)) return node.sum;
    push(tree, index, low, high);
    const auto middle = low + (high - low) / 2;
    return (rectangle_sum(tree, index * 2, low, middle, left, down, right, up) +
            rectangle_sum(tree, index * 2 + 1, middle, high, left, down, right, up)) % mod;
}

void rectangle_affine(std::array<Node, max_tree>& tree, std::size_t index,
        std::size_t low, std::size_t high, std::int64_t left, std::int64_t down,
        std::int64_t right, std::int64_t up, std::int64_t a, std::int64_t b) {
    auto& node = tree[index];
    if (node.active == 0 || disjoint(node, left, down, right, up)) return;
    if (covered(node, left, down, right, up)) {
        apply_node(tree, index, a, b);
        return;
    }
    push(tree, index, low, high);
    const auto middle = low + (high - low) / 2;
    rectangle_affine(tree, index * 2, low, middle, left, down, right, up, a, b);
    rectangle_affine(tree, index * 2 + 1, middle, high, left, down, right, up, a, b);
    pull(tree, index);
}

void set_point(std::array<Node, max_tree>& tree, std::size_t index,
        std::size_t low, std::size_t high, std::size_t target, std::int64_t weight) {
    if (high - low == 1) {
        tree[index].sum = weight;
        tree[index].active = 1;
        tree[index].lazy_a = 1;
        tree[index].lazy_b = 0;
        return;
    }
    push(tree, index, low, high);
    const auto middle = low + (high - low) / 2;
    if (target < middle) set_point(tree, index * 2, low, middle, target, weight);
    else set_point(tree, index * 2 + 1, middle, high, target, weight);
    pull(tree, index);
}

void store_i64_le(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t dynamic_point_set_rectangle_affine_rectangle_sum(
        const std::int64_t* input, std::size_t length,
        std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length < 2 || length > max_parseable_input) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(max_n) ||
        input[1] < 1 || input[1] > static_cast<std::int64_t>(max_q)) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    const auto q = static_cast<std::size_t>(input[1]);
    if (2 + 3 * n > length) return -1;

    std::array<std::int64_t, max_points> xs{}, ys{}, weights{};
    std::array<Operation, max_q> operations{};
    std::size_t point_count = n, active_count = n, query_count = 0, cursor = 2 + 3 * n;
    for (std::size_t i = 0; i < n; ++i) {
        xs[i] = input[2 + 3 * i]; ys[i] = input[3 + 3 * i]; weights[i] = input[4 + 3 * i];
        if (xs[i] < 0 || xs[i] > max_coord || ys[i] < 0 || ys[i] > max_coord ||
            weights[i] < 0 || weights[i] >= mod) return -1;
    }
    for (std::size_t i = 0; i < q; ++i) {
        if (cursor >= length) return -1;
        const auto kind = input[cursor++];
        if (kind == 0) {
            if (cursor + 3 > length || point_count >= max_points) return -1;
            const auto x = input[cursor], y = input[cursor + 1], weight = input[cursor + 2];
            cursor += 3;
            if (x < 0 || x > max_coord || y < 0 || y > max_coord || weight < 0 || weight >= mod)
                return -1;
            xs[point_count] = x; ys[point_count] = y;
            operations[i] = {kind, static_cast<std::int64_t>(point_count), weight, 0, 0, 0, 0};
            ++point_count; ++active_count;
        } else if (kind == 1) {
            if (cursor + 2 > length) return -1;
            const auto point = input[cursor], weight = input[cursor + 1]; cursor += 2;
            if (point < 0 || point >= static_cast<std::int64_t>(active_count) || weight < 0 || weight >= mod)
                return -1;
            operations[i] = {kind, point, weight, 0, 0, 0, 0};
        } else if (kind == 2 || kind == 3) {
            const auto fields = kind == 2 ? 4u : 6u;
            if (cursor + fields > length) return -1;
            const auto left = input[cursor], down = input[cursor + 1];
            const auto right = input[cursor + 2], up = input[cursor + 3];
            if (left < 0 || left >= right || right > max_coord || down < 0 || down >= up || up > max_coord)
                return -1;
            if (kind == 2) {
                cursor += 4;
                operations[i] = {kind, left, down, right, up, 0, 0};
                ++query_count;
            } else {
                const auto a = input[cursor + 4], b = input[cursor + 5]; cursor += 6;
                if (a < 0 || a >= mod || b < 0 || b >= mod) return -1;
                operations[i] = {kind, left, down, right, up, a, b};
            }
        } else return -1;
    }
    if (cursor != length) return -1;
    const auto output_bytes = 8 * query_count;
    if (output_bytes > 0 && (output == nullptr || capacity < output_bytes)) return -2;

    std::array<Node, max_tree> tree{};
    std::array<std::size_t, max_points> order{}, rank{};
    for (std::size_t i = 0; i < point_count; ++i) order[i] = i;
    build_tree(tree, order, xs, ys, weights, rank, 0, point_count, 1, 0, n);
    std::array<std::int64_t, max_q> answers{};
    std::size_t answer_count = 0;
    for (std::size_t i = 0; i < q; ++i) {
        const auto& op = operations[i];
        if (op.kind == 0 || op.kind == 1)
            set_point(tree, 1, 0, point_count, rank[static_cast<std::size_t>(op.a)], op.b);
        else if (op.kind == 2)
            answers[answer_count++] = rectangle_sum(tree, 1, 0, point_count, op.a, op.b, op.c, op.d);
        else rectangle_affine(tree, 1, 0, point_count, op.a, op.b, op.c, op.d, op.e, op.f);
    }
    for (std::size_t i = 0; i < answer_count; ++i) store_i64_le(output, 8 * i, answers[i]);
    return static_cast<std::int64_t>(output_bytes);
}
