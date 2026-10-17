#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_N = 64;
constexpr std::size_t MAX_Q = 64;
constexpr std::size_t MAX_INPUT_LENGTH = 2 + MAX_N + 4 * MAX_Q + 1;
constexpr std::size_t NODE_CAP = 16384;
constexpr std::uint64_t FNV_OFFSET = UINT64_C(14695981039346656037);
constexpr std::uint64_t FNV_PRIME = UINT64_C(1099511628211);

struct Node { std::int64_t sum, prop; std::int32_t left, right; };

std::int32_t make_node(Node *nodes, std::size_t &used, std::int64_t sum,
                       std::int64_t prop, std::int32_t left, std::int32_t right) {
    if (used >= NODE_CAP) return -1;
    const auto index = static_cast<std::int32_t>(used++);
    nodes[index] = {sum, prop, left, right};
    return index;
}

std::int32_t clone_node(Node *nodes, std::size_t &used, std::int32_t source) {
    if (source < 0 || used >= NODE_CAP) return -1;
    const auto index = static_cast<std::int32_t>(used++);
    nodes[index] = nodes[source];
    return index;
}

bool push_lazy(Node *nodes, std::size_t &used, std::int32_t node,
               std::size_t left, std::size_t right) {
    const auto prop = nodes[node].prop;
    if (prop == 0) return true;
    nodes[node].sum += static_cast<std::int64_t>(right - left + 1) * prop;
    if (left != right) {
        const auto new_left = clone_node(nodes, used, nodes[node].left);
        const auto new_right = clone_node(nodes, used, nodes[node].right);
        if (new_left < 0 || new_right < 0) return false;
        nodes[node].left = new_left;
        nodes[node].right = new_right;
        nodes[new_left].prop += prop;
        nodes[new_right].prop += prop;
    }
    nodes[node].prop = 0;
    return true;
}

std::int32_t build(Node *nodes, std::size_t &used, const std::int64_t *values,
                   std::size_t left, std::size_t right) {
    if (left == right) return make_node(nodes, used, values[left], 0, -1, -1);
    const auto mid = left + (right - left) / 2;
    const auto a = build(nodes, used, values, left, mid);
    const auto b = build(nodes, used, values, mid + 1, right);
    if (a < 0 || b < 0) return -1;
    return make_node(nodes, used, nodes[a].sum + nodes[b].sum, 0, a, b);
}

std::int32_t update(Node *nodes, std::size_t &used, std::int32_t current,
                    std::size_t left, std::size_t right, std::size_t ql,
                    std::size_t qr, std::int64_t delta) {
    if (!push_lazy(nodes, used, current, left, right)) return -1;
    if (left >= ql && right <= qr) {
        const auto copy = clone_node(nodes, used, current);
        if (copy < 0) return -1;
        nodes[copy].prop += delta;
        if (!push_lazy(nodes, used, copy, left, right)) return -1;
        return copy;
    }
    if (left > qr || right < ql) return current;

    const auto copy = make_node(nodes, used, 0, 0, -1, -1);
    if (copy < 0) return -1;
    const auto mid = left + (right - left) / 2;
    const auto a = update(nodes, used, nodes[current].left, left, mid, ql, qr, delta);
    const auto b = update(nodes, used, nodes[current].right, mid + 1, right, ql, qr, delta);
    if (a < 0 || b < 0) return -1;
    nodes[copy].left = a;
    nodes[copy].right = b;
    nodes[copy].sum = nodes[a].sum + nodes[b].sum;
    return copy;
}

std::int64_t query(Node *nodes, std::size_t &used, std::int32_t node,
                   std::size_t left, std::size_t right, std::size_t ql,
                   std::size_t qr, bool &ok) {
    if (!push_lazy(nodes, used, node, left, right)) { ok = false; return 0; }
    if (right < ql || qr < left) return 0;
    if (ql <= left && right <= qr) return nodes[node].sum;
    const auto mid = left + (right - left) / 2;
    const auto a = query(nodes, used, nodes[node].left, left, mid, ql, qr, ok);
    if (!ok) return 0;
    const auto b = query(nodes, used, nodes[node].right, mid + 1, right, ql, qr, ok);
    return a + b;
}

std::uint64_t hash_word(std::uint64_t hash, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (unsigned shift = 0; shift < 64; shift += 8)
        hash = (hash ^ static_cast<std::uint8_t>(bits >> shift)) * FNV_PRIME;
    return hash;
}
}

extern "C" std::int64_t persistent_seg_tree_lazy_prop(const std::int64_t *input,
                                                        std::size_t length) {
    if (input == nullptr || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    const auto n64 = input[0], q64 = input[1];
    if (n64 < 1 || n64 > static_cast<std::int64_t>(MAX_N)
        || q64 < 0 || q64 > static_cast<std::int64_t>(MAX_Q)) return -1;
    const auto n = static_cast<std::size_t>(n64), q = static_cast<std::size_t>(q64);
    if (length != 2 + n + 4 * q) return -1;

    std::int64_t values[MAX_N];
    for (std::size_t index = 0; index < n; ++index) {
        values[index] = input[2 + index];
        if (values[index] < -1000 || values[index] > 1000) return -1;
    }

    Node nodes[NODE_CAP];
    std::size_t used = 0;
    std::int32_t roots[MAX_Q + 1];
    roots[0] = build(nodes, used, values, 0, n - 1);
    if (roots[0] < 0) return -1;
    std::size_t version_count = 1, query_count = 0, offset = 2 + n;
    std::int64_t query_sums[MAX_Q];

    for (std::size_t operation_index = 0; operation_index < q; ++operation_index, offset += 4) {
        const auto op = input[offset], a = input[offset + 1];
        const auto b = input[offset + 2], c = input[offset + 3];
        if (op == 0) {
            if (a < 0 || a > b || b >= n64 || c < -1000 || c > 1000) return -1;
            const auto next = update(nodes, used, roots[version_count - 1], 0, n - 1,
                                     static_cast<std::size_t>(a), static_cast<std::size_t>(b), c);
            if (next < 0) return -1;
            roots[version_count++] = next;
        } else if (op == 1) {
            if (a < 0 || static_cast<std::uint64_t>(a) >= version_count
                || b < 0 || c < b || c >= n64) return -1;
            bool ok = true;
            query_sums[query_count] = query(nodes, used, roots[static_cast<std::size_t>(a)],
                                            0, n - 1, static_cast<std::size_t>(b),
                                            static_cast<std::size_t>(c), ok);
            if (!ok) return -1;
            ++query_count;
        } else return -1;
    }

    auto hash = hash_word(FNV_OFFSET, static_cast<std::int64_t>(version_count));
    hash = hash_word(hash, static_cast<std::int64_t>(query_count));
    for (std::size_t index = 0; index < query_count; ++index) hash = hash_word(hash, query_sums[index]);
    return static_cast<std::int64_t>(hash & UINT64_C(0x7fffffffffffffff));
}
