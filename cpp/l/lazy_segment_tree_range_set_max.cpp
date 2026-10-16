#include <algorithm>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MaxN = 256, MaxQ = 512, MaxInput = 2306;
constexpr std::int64_t Offset = 1000001;
using Tree = std::int64_t[1024];
using Flags = unsigned char[1024];

void build(std::size_t node, std::size_t left, std::size_t right, const std::int64_t *values, Tree &tree) {
    if (left == right) { tree[node] = values[left]; return; }
    const auto mid = left + (right - left) / 2;
    build(node * 2, left, mid, values, tree);
    build(node * 2 + 1, mid + 1, right, values, tree);
    tree[node] = std::max(tree[node * 2], tree[node * 2 + 1]);
}
void push(std::size_t node, std::size_t left, std::size_t right, Tree &tree, Tree &lazy, Flags &pending) {
    if (!pending[node]) return;
    tree[node] = lazy[node]; pending[node] = 0;
    if (left != right) {
        const auto a = node * 2;
        lazy[a] = lazy[a + 1] = tree[node]; pending[a] = pending[a + 1] = 1;
    }
}
void assign_range(std::size_t node, std::size_t left, std::size_t right, std::size_t ql, std::size_t qr,
                  std::int64_t value, Tree &tree, Tree &lazy, Flags &pending) {
    push(node, left, right, tree, lazy, pending);
    if (right < ql || left > qr) return;
    if (ql <= left && right <= qr) {
        tree[node] = value;
        if (left != right) { const auto a = node * 2; lazy[a] = lazy[a + 1] = value; pending[a] = pending[a + 1] = 1; }
        return;
    }
    const auto mid = left + (right - left) / 2;
    assign_range(node * 2, left, mid, ql, qr, value, tree, lazy, pending);
    assign_range(node * 2 + 1, mid + 1, right, ql, qr, value, tree, lazy, pending);
    tree[node] = std::max(tree[node * 2], tree[node * 2 + 1]);
}
std::int64_t range_max(std::size_t node, std::size_t left, std::size_t right, std::size_t ql, std::size_t qr,
                       Tree &tree, Tree &lazy, Flags &pending) {
    push(node, left, right, tree, lazy, pending);
    if (right < ql || left > qr) return INT64_MIN;
    if (ql <= left && right <= qr) return tree[node];
    const auto mid = left + (right - left) / 2;
    return std::max(range_max(node * 2, left, mid, ql, qr, tree, lazy, pending),
                    range_max(node * 2 + 1, mid + 1, right, ql, qr, tree, lazy, pending));
}
}

extern "C" std::int64_t lazy_segment_tree_range_set_max(const std::int64_t *packed, std::size_t length) noexcept {
    if (packed == nullptr || length < 2 || length > MaxInput) return -1;
    const auto nv = packed[0], qv = packed[1];
    if (nv < 1 || nv > static_cast<std::int64_t>(MaxN) || qv < 0 || qv > static_cast<std::int64_t>(MaxQ)) return -1;
    const auto n = static_cast<std::size_t>(nv), q = static_cast<std::size_t>(qv);
    if (length < 2 + n) return -1;
    std::int64_t initial[MaxN];
    for (std::size_t i = 0; i < n; ++i) { initial[i] = packed[2 + i]; if (initial[i] < -1000000 || initial[i] > 1000000) return -1; }
    std::size_t offset = 2 + n;
    unsigned char opcode[MaxQ]{};
    std::size_t left[MaxQ]{}, right[MaxQ]{};
    std::int64_t assigned[MaxQ]{};
    for (std::size_t i = 0; i < q; ++i) {
        if (offset >= length) return -1;
        const auto op = packed[offset];
        const std::size_t width = op == 0 ? 3 : op == 1 ? 4 : 0;
        if (width == 0 || offset + width > length) return -1;
        const auto l = packed[offset + 1], r = packed[offset + 2];
        if (l < 0 || l >= r || r > nv) return -1;
        opcode[i] = static_cast<unsigned char>(op); left[i] = static_cast<std::size_t>(l); right[i] = static_cast<std::size_t>(r);
        if (op == 1) { assigned[i] = packed[offset + 3]; if (assigned[i] < -1000000 || assigned[i] > 1000000) return -1; }
        offset += width;
    }
    if (offset != length) return -1;
    Tree tree{}; Tree lazy{}; Flags pending{};
    build(1, 0, n - 1, initial, tree);
    std::int64_t checksum = 0, ordinal = 0;
    for (std::size_t i = 0; i < q; ++i) {
        if (opcode[i] == 1) assign_range(1, 0, n - 1, left[i], right[i] - 1, assigned[i], tree, lazy, pending);
        else { const auto answer = range_max(1, 0, n - 1, left[i], right[i] - 1, tree, lazy, pending); ++ordinal; checksum += ordinal * (answer + Offset); }
    }
    return checksum;
}
