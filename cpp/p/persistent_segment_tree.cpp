#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_N = 64, MAX_Q = 64, MAX_INPUT = 322, NODE_CAP = 640;
constexpr std::uint64_t FNV_OFFSET = UINT64_C(14695981039346656037);
constexpr std::uint64_t FNV_PRIME = UINT64_C(1099511628211);
struct Node { std::int64_t sum; std::int32_t left, right; };

std::int32_t make_node(Node *nodes, std::size_t &used, std::int64_t sum, std::int32_t left, std::int32_t right) {
    if (used >= NODE_CAP) return -1;
    const auto index = static_cast<std::int32_t>(used++);
    nodes[index] = {sum, left, right}; return index;
}
std::int32_t build(Node *nodes, std::size_t &used, const std::int64_t *values, std::size_t left, std::size_t right) {
    if (left == right) return make_node(nodes, used, values[left], -1, -1);
    const auto mid = left + (right - left) / 2;
    const auto a = build(nodes, used, values, left, mid), b = build(nodes, used, values, mid + 1, right);
    if (a < 0 || b < 0) return -1;
    return make_node(nodes, used, nodes[a].sum + nodes[b].sum, a, b);
}
std::int32_t point_set(Node *nodes, std::size_t &used, std::int32_t root, std::size_t left, std::size_t right, std::size_t index, std::int64_t value) {
    if (left == right) return make_node(nodes, used, value, -1, -1);
    const auto mid = left + (right - left) / 2;
    auto a = nodes[root].left, b = nodes[root].right;
    if (index <= mid) a = point_set(nodes, used, a, left, mid, index, value);
    else b = point_set(nodes, used, b, mid + 1, right, index, value);
    if (a < 0 || b < 0) return -1;
    return make_node(nodes, used, nodes[a].sum + nodes[b].sum, a, b);
}
std::int64_t range_sum(const Node *nodes, std::int32_t node, std::size_t left, std::size_t right, std::size_t ql, std::size_t qr) {
    if (ql <= left && right <= qr) return nodes[node].sum;
    const auto mid = left + (right - left) / 2;
    std::int64_t total = 0;
    if (ql <= mid) total += range_sum(nodes, nodes[node].left, left, mid, ql, qr);
    if (qr > mid) total += range_sum(nodes, nodes[node].right, mid + 1, right, ql, qr);
    return total;
}
std::uint64_t hash_word(std::uint64_t hash, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (unsigned shift = 0; shift < 64; shift += 8) hash = (hash ^ static_cast<std::uint8_t>(bits >> shift)) * FNV_PRIME;
    return hash;
}
}

extern "C" std::int64_t persistent_segment_tree(const std::int64_t *input, std::size_t length) {
    if (input == nullptr || length < 3 || length > MAX_INPUT) return -1;
    const auto n64 = input[0], q64 = input[1];
    if (n64 < 1 || n64 > static_cast<std::int64_t>(MAX_N) || q64 < 0 || q64 > static_cast<std::int64_t>(MAX_Q)) return -1;
    const auto n = static_cast<std::size_t>(n64), q = static_cast<std::size_t>(q64);
    if (length != 2 + n + 4 * q) return -1;
    std::int64_t values[MAX_N];
    for (std::size_t i = 0; i < n; ++i) { values[i] = input[2 + i]; if (values[i] < -1000 || values[i] > 1000) return -1; }
    Node nodes[NODE_CAP]; std::size_t used = 0;
    std::int32_t roots[MAX_Q + 1]; roots[0] = build(nodes, used, values, 0, n - 1);
    if (roots[0] < 0) return -1;
    std::size_t version_count = 1, query_count = 0, offset = 2 + n;
    std::int64_t query_sums[MAX_Q];
    for (std::size_t i = 0; i < q; ++i, offset += 4) {
        const auto op = input[offset], a = input[offset + 1], b = input[offset + 2], c = input[offset + 3];
        if (op == 0) {
            if (a < 0 || static_cast<std::uint64_t>(a) >= version_count || b < 0 || b >= n64 || c < -1000 || c > 1000) return -1;
            const auto next = point_set(nodes, used, roots[a], 0, n - 1, static_cast<std::size_t>(b), c);
            if (next < 0) return -1;
            roots[version_count++] = next;
        } else if (op == 1) {
            if (a < 0 || static_cast<std::uint64_t>(a) >= version_count || b < 0 || c < b || c >= n64) return -1;
            query_sums[query_count++] = range_sum(nodes, roots[a], 0, n - 1, static_cast<std::size_t>(b), static_cast<std::size_t>(c));
        } else return -1;
    }
    auto hash = hash_word(FNV_OFFSET, static_cast<std::int64_t>(version_count));
    hash = hash_word(hash, static_cast<std::int64_t>(query_count));
    for (std::size_t i = 0; i < query_count; ++i) hash = hash_word(hash, query_sums[i]);
    return static_cast<std::int64_t>(hash & UINT64_C(0x7fffffffffffffff));
}
