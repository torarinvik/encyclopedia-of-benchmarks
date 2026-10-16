#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_ITEMS = 256;
constexpr std::size_t MAX_OPERATIONS = 512;
constexpr std::size_t MAX_INPUT_LENGTH = 2 + MAX_ITEMS + 4 * MAX_OPERATIONS;
constexpr std::int64_t VALUE_LIMIT = 1'000'000;
constexpr std::int64_t QUERY_OFFSET = 131'328'000'001;

void apply(std::int64_t *tree, std::int64_t *lazy, std::size_t node,
           std::size_t segment_length, std::int64_t delta) {
    tree[node] += delta * static_cast<std::int64_t>(segment_length);
    lazy[node] += delta;
}

void push(std::int64_t *tree, std::int64_t *lazy, std::size_t node, std::size_t segment_length) {
    if (segment_length > 1 && lazy[node] != 0) {
        const auto child_length = segment_length / 2;
        apply(tree, lazy, 2 * node, child_length, lazy[node]);
        apply(tree, lazy, 2 * node + 1, child_length, lazy[node]);
        lazy[node] = 0;
    }
}

void range_add(std::int64_t *tree, std::int64_t *lazy, std::size_t node,
               std::size_t low, std::size_t high, std::size_t query_low,
               std::size_t query_high, std::int64_t delta) {
    if (query_low <= low && high <= query_high) {
        apply(tree, lazy, node, high - low, delta);
        return;
    }
    push(tree, lazy, node, high - low);
    const auto middle = (low + high) / 2;
    if (query_low < middle) range_add(tree, lazy, 2 * node, low, middle, query_low, query_high, delta);
    if (query_high > middle) range_add(tree, lazy, 2 * node + 1, middle, high, query_low, query_high, delta);
    tree[node] = tree[2 * node] + tree[2 * node + 1];
}

std::int64_t range_sum(std::int64_t *tree, std::int64_t *lazy, std::size_t node,
                       std::size_t low, std::size_t high, std::size_t query_low,
                       std::size_t query_high) {
    if (query_low <= low && high <= query_high) return tree[node];
    push(tree, lazy, node, high - low);
    const auto middle = (low + high) / 2;
    std::int64_t result = 0;
    if (query_low < middle) result += range_sum(tree, lazy, 2 * node, low, middle, query_low, query_high);
    if (query_high > middle) result += range_sum(tree, lazy, 2 * node + 1, middle, high, query_low, query_high);
    return result;
}
}

extern "C" std::int64_t lazy_segment_tree_range_add_sum(const std::int64_t *values,
                                                         std::size_t length) noexcept {
    if (values == nullptr || length < 3 || length > MAX_INPUT_LENGTH) return -1;
    const auto item_count_value = values[0];
    if (item_count_value < 1 || item_count_value > static_cast<std::int64_t>(MAX_ITEMS)) return -1;
    const auto item_count = static_cast<std::size_t>(item_count_value);
    if (length < item_count + 2) return -1;
    const auto operation_count_value = values[item_count + 1];
    if (operation_count_value < 0 || operation_count_value > static_cast<std::int64_t>(MAX_OPERATIONS)) return -1;
    const auto operation_count = static_cast<std::size_t>(operation_count_value);
    if (length != item_count + 2 + 4 * operation_count) return -1;

    for (std::size_t i = 0; i < item_count; ++i)
        if (values[i + 1] < -VALUE_LIMIT || values[i + 1] > VALUE_LIMIT) return -1;
    for (std::size_t operation = 0; operation < operation_count; ++operation) {
        const auto position = item_count + 2 + 4 * operation;
        const auto opcode = values[position];
        const auto left = values[position + 1];
        const auto right = values[position + 2];
        const auto delta = values[position + 3];
        if (left < 0 || left >= right || right > item_count_value) return -1;
        if (opcode == 0) {
            if (delta < -VALUE_LIMIT || delta > VALUE_LIMIT) return -1;
        } else if (opcode == 1) {
            if (delta != 0) return -1;
        } else return -1;
    }

    std::size_t base = 1;
    while (base < item_count) base *= 2;
    std::int64_t tree[2 * MAX_ITEMS] = {};
    std::int64_t lazy[2 * MAX_ITEMS] = {};
    for (std::size_t i = 0; i < item_count; ++i) tree[base + i] = values[i + 1];
    for (std::size_t node = base; node-- > 1;) tree[node] = tree[2 * node] + tree[2 * node + 1];

    std::int64_t checksum = 0;
    for (std::size_t operation = 0; operation < operation_count; ++operation) {
        const auto position = item_count + 2 + 4 * operation;
        const auto left = static_cast<std::size_t>(values[position + 1]);
        const auto right = static_cast<std::size_t>(values[position + 2]);
        if (values[position] == 0)
            range_add(tree, lazy, 1, 0, base, left, right, values[position + 3]);
        else
            checksum += range_sum(tree, lazy, 1, 0, base, left, right) + QUERY_OFFSET;
    }
    return checksum;
}
