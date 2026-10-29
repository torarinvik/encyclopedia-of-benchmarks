#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_ITEMS = 64;
constexpr std::size_t MAX_OPERATIONS = 128;
constexpr std::size_t MAX_INPUT_VALUES = 2 + MAX_ITEMS + 4 * MAX_OPERATIONS;
constexpr std::int64_t VALUE_LIMIT = 1'000'000;
constexpr std::int64_t INF = INT64_MAX / 4;
constexpr std::int64_t QUERY_OFFSET = 8'256'000'001;

struct Node {
    std::int64_t sum, max1, max2, min1, min2, add;
    std::size_t max_count, min_count;
};

void pull(Node* tree, std::size_t node) {
    const Node& left = tree[2 * node];
    const Node& right = tree[2 * node + 1];
    Node& current = tree[node];
    current.sum = left.sum + right.sum;
    current.add = 0;
    if (left.max1 == right.max1) {
        current.max1 = left.max1;
        current.max2 = left.max2 > right.max2 ? left.max2 : right.max2;
        current.max_count = left.max_count + right.max_count;
    } else if (left.max1 > right.max1) {
        current.max1 = left.max1;
        current.max2 = left.max2 > right.max1 ? left.max2 : right.max1;
        current.max_count = left.max_count;
    } else {
        current.max1 = right.max1;
        current.max2 = left.max1 > right.max2 ? left.max1 : right.max2;
        current.max_count = right.max_count;
    }
    if (left.min1 == right.min1) {
        current.min1 = left.min1;
        current.min2 = left.min2 < right.min2 ? left.min2 : right.min2;
        current.min_count = left.min_count + right.min_count;
    } else if (left.min1 < right.min1) {
        current.min1 = left.min1;
        current.min2 = left.min2 < right.min1 ? left.min2 : right.min1;
        current.min_count = left.min_count;
    } else {
        current.min1 = right.min1;
        current.min2 = left.min1 < right.min2 ? left.min1 : right.min2;
        current.min_count = right.min_count;
    }
}

void build(Node* tree, const std::int64_t* values, std::size_t node,
           std::size_t low, std::size_t high) {
    if (high - low == 1) {
        const auto value = values[low];
        tree[node] = Node{value, value, -INF, value, INF, 0, 1, 1};
        return;
    }
    const auto middle = low + (high - low) / 2;
    build(tree, values, 2 * node, low, middle);
    build(tree, values, 2 * node + 1, middle, high);
    pull(tree, node);
}

void apply_add(Node& item, std::size_t length, std::int64_t delta) {
    item.sum += delta * static_cast<std::int64_t>(length);
    item.max1 += delta;
    item.min1 += delta;
    if (item.max2 != -INF) item.max2 += delta;
    if (item.min2 != INF) item.min2 += delta;
    item.add += delta;
}

void apply_chmin(Node& item, std::int64_t ceiling) {
    if (item.max1 <= ceiling) return;
    item.sum += (ceiling - item.max1) * static_cast<std::int64_t>(item.max_count);
    if (item.min1 == item.max1) item.min1 = ceiling;
    else if (item.min2 == item.max1) item.min2 = ceiling;
    item.max1 = ceiling;
}

void apply_chmax(Node& item, std::int64_t floor) {
    if (item.min1 >= floor) return;
    item.sum += (floor - item.min1) * static_cast<std::int64_t>(item.min_count);
    if (item.max1 == item.min1) item.max1 = floor;
    else if (item.max2 == item.min1) item.max2 = floor;
    item.min1 = floor;
}

void push(Node* tree, std::size_t node, std::size_t low, std::size_t high) {
    if (high - low == 1) return;
    const auto middle = low + (high - low) / 2;
    Node& parent = tree[node];
    Node& left = tree[2 * node];
    Node& right = tree[2 * node + 1];
    if (parent.add != 0) {
        apply_add(left, middle - low, parent.add);
        apply_add(right, high - middle, parent.add);
        parent.add = 0;
    }
    if (left.max1 > parent.max1) apply_chmin(left, parent.max1);
    if (right.max1 > parent.max1) apply_chmin(right, parent.max1);
    if (left.min1 < parent.min1) apply_chmax(left, parent.min1);
    if (right.min1 < parent.min1) apply_chmax(right, parent.min1);
}

void range_add(Node* tree, std::size_t node, std::size_t low, std::size_t high,
               std::size_t ql, std::size_t qr, std::int64_t delta) {
    if (qr <= low || high <= ql || delta == 0) return;
    if (ql <= low && high <= qr) {
        apply_add(tree[node], high - low, delta);
        return;
    }
    push(tree, node, low, high);
    const auto middle = low + (high - low) / 2;
    range_add(tree, 2 * node, low, middle, ql, qr, delta);
    range_add(tree, 2 * node + 1, middle, high, ql, qr, delta);
    pull(tree, node);
}

void range_chmin(Node* tree, std::size_t node, std::size_t low, std::size_t high,
                 std::size_t ql, std::size_t qr, std::int64_t ceiling) {
    Node& item = tree[node];
    if (qr <= low || high <= ql || item.max1 <= ceiling) return;
    if (ql <= low && high <= qr && item.max2 < ceiling) {
        apply_chmin(item, ceiling);
        return;
    }
    push(tree, node, low, high);
    const auto middle = low + (high - low) / 2;
    range_chmin(tree, 2 * node, low, middle, ql, qr, ceiling);
    range_chmin(tree, 2 * node + 1, middle, high, ql, qr, ceiling);
    pull(tree, node);
}

void range_chmax(Node* tree, std::size_t node, std::size_t low, std::size_t high,
                 std::size_t ql, std::size_t qr, std::int64_t floor) {
    Node& item = tree[node];
    if (qr <= low || high <= ql || item.min1 >= floor) return;
    if (ql <= low && high <= qr && item.min2 > floor) {
        apply_chmax(item, floor);
        return;
    }
    push(tree, node, low, high);
    const auto middle = low + (high - low) / 2;
    range_chmax(tree, 2 * node, low, middle, ql, qr, floor);
    range_chmax(tree, 2 * node + 1, middle, high, ql, qr, floor);
    pull(tree, node);
}

std::int64_t range_sum(Node* tree, std::size_t node, std::size_t low,
                       std::size_t high, std::size_t ql, std::size_t qr) {
    if (qr <= low || high <= ql) return 0;
    if (ql <= low && high <= qr) return tree[node].sum;
    push(tree, node, low, high);
    const auto middle = low + (high - low) / 2;
    return range_sum(tree, 2 * node, low, middle, ql, qr) +
           range_sum(tree, 2 * node + 1, middle, high, ql, qr);
}
} // namespace

extern "C" std::int64_t segment_tree_beats(const std::int64_t* values, std::size_t length) {
    if (values == nullptr || length < 2 || length > MAX_INPUT_VALUES) return -1;
    if (values[0] < 1 || values[0] > static_cast<std::int64_t>(MAX_ITEMS)) return -1;
    const auto n = static_cast<std::size_t>(values[0]);
    if (length < n + 2 || values[n + 1] < 0 || values[n + 1] > static_cast<std::int64_t>(MAX_OPERATIONS)) return -1;
    const auto q = static_cast<std::size_t>(values[n + 1]);
    if (length != n + 2 + 4 * q) return -1;
    for (std::size_t i = 0; i < n; ++i)
        if (values[i + 1] < -VALUE_LIMIT || values[i + 1] > VALUE_LIMIT) return -1;
    for (std::size_t i = 0; i < q; ++i) {
        const auto p = n + 2 + 4 * i;
        const auto op = values[p], left = values[p + 1], right = values[p + 2], argument = values[p + 3];
        if (op < 0 || op > 3 || left < 0 || left >= right || right > static_cast<std::int64_t>(n)) return -1;
        if (op == 3 ? argument != 0 : argument < -VALUE_LIMIT || argument > VALUE_LIMIT) return -1;
    }

    Node tree[4 * MAX_ITEMS]{};
    build(tree, values + 1, 1, 0, n);
    std::int64_t checksum = 0, query_ordinal = 0;
    for (std::size_t i = 0; i < q; ++i) {
        const auto p = n + 2 + 4 * i;
        const auto left = static_cast<std::size_t>(values[p + 1]);
        const auto right = static_cast<std::size_t>(values[p + 2]);
        const auto argument = values[p + 3];
        switch (values[p]) {
        case 0: range_chmin(tree, 1, 0, n, left, right, argument); break;
        case 1: range_chmax(tree, 1, 0, n, left, right, argument); break;
        case 2: range_add(tree, 1, 0, n, left, right, argument); break;
        default:
            ++query_ordinal;
            checksum += query_ordinal * (range_sum(tree, 1, 0, n, left, right) + QUERY_OFFSET);
        }
    }
    return checksum;
}
