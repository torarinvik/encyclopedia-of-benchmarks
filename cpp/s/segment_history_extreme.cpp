// Historical maximum segment tree with ordered lazy add/assign summaries.
#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <limits>

namespace {
constexpr std::size_t max_n = 32;
constexpr std::size_t max_q = 32;
constexpr std::size_t tree_size = 4 * max_n;
constexpr std::int64_t value_limit = 1000;

struct Node {
    std::int64_t maximum = 0;
    std::int64_t history_maximum = 0;
    std::int64_t add = 0;
    std::int64_t add_peak = 0;
    std::int64_t set_value = 0;
    std::int64_t set_peak = 0;
    bool has_set = false;
};

void apply_add_summary(Node &node, std::int64_t net, std::int64_t peak) {
    node.history_maximum = std::max(node.history_maximum, node.maximum + peak);
    node.maximum += net;
    if (node.has_set) {
        node.set_peak = std::max(node.set_peak, node.set_value + peak);
        node.set_value += net;
    } else {
        node.add_peak = std::max(node.add_peak, node.add + peak);
        node.add += net;
    }
}

void apply_add(Node &node, std::int64_t delta) {
    if (node.has_set) {
        node.set_peak = std::max(node.set_peak, node.set_value + delta);
        node.set_value += delta;
    } else {
        node.add_peak = std::max(node.add_peak, node.add + delta);
        node.add += delta;
    }
    node.history_maximum = std::max(node.history_maximum, node.maximum + delta);
    node.maximum += delta;
}

void apply_set_summary(Node &node, std::int64_t value, std::int64_t peak) {
    node.history_maximum = std::max(node.history_maximum, peak);
    node.maximum = value;
    if (node.has_set) node.set_peak = std::max(node.set_peak, peak);
    else { node.has_set = true; node.set_peak = peak; }
    node.set_value = value;
}

void apply_set(Node &node, std::int64_t value) {
    node.history_maximum = std::max(node.history_maximum, value);
    node.maximum = value;
    if (node.has_set) node.set_peak = std::max(node.set_peak, value);
    else { node.has_set = true; node.set_peak = value; }
    node.set_value = value;
}

void push(Node (&tree)[tree_size], std::size_t node) {
    Node &parent = tree[node];
    if (parent.add != 0 || parent.add_peak != 0) {
        apply_add_summary(tree[2 * node], parent.add, parent.add_peak);
        apply_add_summary(tree[2 * node + 1], parent.add, parent.add_peak);
        parent.add = 0;
        parent.add_peak = 0;
    }
    if (parent.has_set) {
        apply_set_summary(tree[2 * node], parent.set_value, parent.set_peak);
        apply_set_summary(tree[2 * node + 1], parent.set_value, parent.set_peak);
        parent.has_set = false;
        parent.set_value = 0;
        parent.set_peak = 0;
    }
}

void pull(Node (&tree)[tree_size], std::size_t node) {
    tree[node].maximum = std::max(tree[2 * node].maximum, tree[2 * node + 1].maximum);
    tree[node].history_maximum = std::max(tree[2 * node].history_maximum,
                                          tree[2 * node + 1].history_maximum);
}

void build(Node (&tree)[tree_size], const std::int64_t *input, std::size_t offset,
           std::size_t node, std::size_t left, std::size_t right) {
    if (right - left == 1) {
        tree[node].maximum = input[offset + left];
        tree[node].history_maximum = input[offset + left];
        return;
    }
    const std::size_t middle = left + (right - left) / 2;
    build(tree, input, offset, 2 * node, left, middle);
    build(tree, input, offset, 2 * node + 1, middle, right);
    pull(tree, node);
}

void update(Node (&tree)[tree_size], std::size_t node, std::size_t left, std::size_t right,
            std::size_t ql, std::size_t qr, bool assignment, std::int64_t value) {
    if (ql <= left && right <= qr) {
        if (assignment) apply_set(tree[node], value); else apply_add(tree[node], value);
        return;
    }
    push(tree, node);
    const std::size_t middle = left + (right - left) / 2;
    if (ql < middle) update(tree, 2 * node, left, middle, ql, qr, assignment, value);
    if (middle < qr) update(tree, 2 * node + 1, middle, right, ql, qr, assignment, value);
    pull(tree, node);
}

std::int64_t query(Node (&tree)[tree_size], std::size_t node, std::size_t left,
                   std::size_t right, std::size_t ql, std::size_t qr, bool history) {
    if (ql <= left && right <= qr) return history ? tree[node].history_maximum : tree[node].maximum;
    push(tree, node);
    const std::size_t middle = left + (right - left) / 2;
    std::int64_t answer = std::numeric_limits<std::int64_t>::min();
    if (ql < middle) answer = query(tree, 2 * node, left, middle, ql, qr, history);
    if (middle < qr) answer = std::max(answer, query(tree, 2 * node + 1, middle, right, ql, qr, history));
    return answer;
}

void write_i64(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    const std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t segment_history_extreme(const std::int64_t *input,
    std::size_t input_length, std::uint8_t *output, std::size_t output_capacity) {
    if (input == nullptr || input_length < 2 || input_length > 2 + max_n + 4 * max_q) return -1;
    const std::int64_t n_value = input[0], q_value = input[1];
    if (n_value < 1 || n_value > static_cast<std::int64_t>(max_n) || q_value < 0 || q_value > static_cast<std::int64_t>(max_q)) return -1;
    const std::size_t n = static_cast<std::size_t>(n_value), q = static_cast<std::size_t>(q_value);
    if (input_length != 2 + n + 4 * q) return -1;
    const std::size_t operation_offset = 2 + n;
    for (std::size_t i = 0; i < n; ++i) if (input[2 + i] < -value_limit || input[2 + i] > value_limit) return -1;
    for (std::size_t i = 0; i < q; ++i) {
        const std::int64_t *record = input + operation_offset + 4 * i;
        const auto op = record[0], left = record[1], right = record[2], arg = record[3];
        if (op < 0 || op > 3 || left < 0 || right <= left || right > n_value) return -1;
        if (op < 2 ? (arg < -value_limit || arg > value_limit) : arg != 0) return -1;
    }

    Node tree[tree_size]{};
    std::int64_t staged[max_q]{};
    std::size_t answer_count = 0;
    build(tree, input, 2, 1, 0, n);
    for (std::size_t i = 0; i < q; ++i) {
        const std::int64_t *record = input + operation_offset + 4 * i;
        const int op = static_cast<int>(record[0]);
        const auto left = static_cast<std::size_t>(record[1]);
        const auto right = static_cast<std::size_t>(record[2]);
        if (op < 2) update(tree, 1, 0, n, left, right, op == 0, record[3]);
        else staged[answer_count++] = query(tree, 1, 0, n, left, right, op == 3);
    }
    const std::size_t output_bytes = 8 * answer_count;
    if (output == nullptr || output_capacity < output_bytes) return -2;
    for (std::size_t i = 0; i < answer_count; ++i) write_i64(output, 8 * i, staged[i]);
    return static_cast<std::int64_t>(output_bytes);
}
