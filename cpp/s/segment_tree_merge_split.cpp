#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int kDomain = 64, kMaxQ = 32, kMaxRoots = 33, kMaxNodes = 1024;
constexpr std::size_t kMaxInput = 131, kMaxOutput = 256;
struct Node { int left = 0, right = 0; std::int64_t total = 0; };
struct Operation { std::int64_t op, a, b, c; };

int allocate(std::array<Node, kMaxNodes>& nodes, int& used) {
    if (used >= kMaxNodes) return -1;
    const int id = used++;
    nodes[static_cast<std::size_t>(id)] = {};
    return id;
}
int insert(std::array<Node, kMaxNodes>& nodes, int& used, int node, int lo, int hi, int value, int amount) {
    if (node == 0 && (node = allocate(nodes, used)) < 0) return -1;
    if (lo == hi) { nodes[node].total += amount; return node; }
    const int mid = (lo + hi) / 2;
    if (value <= mid) {
        const int child = insert(nodes, used, nodes[node].left, lo, mid, value, amount);
        if (child < 0) return -1;
        nodes[node].left = child;
    } else {
        const int child = insert(nodes, used, nodes[node].right, mid + 1, hi, value, amount);
        if (child < 0) return -1;
        nodes[node].right = child;
    }
    nodes[node].total = nodes[nodes[node].left].total + nodes[nodes[node].right].total;
    return node;
}
int merge_nodes(std::array<Node, kMaxNodes>& nodes, int a, int b, int lo, int hi) {
    if (a == 0) return b;
    if (b == 0) return a;
    if (lo == hi) { nodes[a].total += nodes[b].total; return a; }
    const int mid = (lo + hi) / 2;
    nodes[a].left = merge_nodes(nodes, nodes[a].left, nodes[b].left, lo, mid);
    nodes[a].right = merge_nodes(nodes, nodes[a].right, nodes[b].right, mid + 1, hi);
    nodes[a].total = nodes[nodes[a].left].total + nodes[nodes[a].right].total;
    return a;
}
int split(std::array<Node, kMaxNodes>& nodes, int& used, int node, int lo, int hi,
          int ql, int qr, int& moved) {
    moved = 0;
    if (node == 0 || qr < lo || hi < ql) return node;
    if (ql <= lo && hi <= qr) { moved = node; return 0; }
    const int mid = (lo + hi) / 2;
    int moved_left = 0, moved_right = 0;
    const int remain_left = split(nodes, used, nodes[node].left, lo, mid, ql, qr, moved_left);
    if (remain_left < 0) return -1;
    const int remain_right = split(nodes, used, nodes[node].right, mid + 1, hi, ql, qr, moved_right);
    if (remain_right < 0) return -1;
    nodes[node].left = remain_left; nodes[node].right = remain_right;
    nodes[node].total = nodes[remain_left].total + nodes[remain_right].total;
    if (moved_left != 0 || moved_right != 0) {
        moved = allocate(nodes, used);
        if (moved < 0) return -1;
        nodes[moved].left = moved_left; nodes[moved].right = moved_right;
        nodes[moved].total = nodes[moved_left].total + nodes[moved_right].total;
    }
    return node;
}
std::int64_t range_sum(const std::array<Node, kMaxNodes>& nodes, int node, int lo, int hi, int ql, int qr) {
    if (node == 0 || qr < lo || hi < ql) return 0;
    if (ql <= lo && hi <= qr) return nodes[node].total;
    const int mid = (lo + hi) / 2;
    return range_sum(nodes, nodes[node].left, lo, mid, ql, qr)
         + range_sum(nodes, nodes[node].right, mid + 1, hi, ql, qr);
}
std::int64_t kth(const std::array<Node, kMaxNodes>& nodes, int node, int lo, int hi, std::int64_t k) {
    if (node == 0 || k > nodes[node].total) return -1;
    if (lo == hi) return lo;
    const int mid = (lo + hi) / 2, left = nodes[node].left;
    return k <= nodes[left].total ? kth(nodes, left, lo, mid, k)
         : kth(nodes, nodes[node].right, mid + 1, hi, k - nodes[left].total);
}
void pack_i64(std::array<std::uint8_t, kMaxOutput>& out, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t i = 0; i < 8; ++i) out[offset + i] = static_cast<std::uint8_t>(bits >> (8 * i));
}
}

extern "C" std::int64_t segment_tree_merge_split(const std::int64_t* input, std::size_t length,
                                                   std::uint8_t* output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 2 || length > kMaxInput || input[0] != kDomain
        || input[1] < 0 || input[1] > kMaxQ || length != 2 + 4 * static_cast<std::size_t>(input[1])) return -1;
    const auto q = static_cast<std::size_t>(input[1]);
    std::array<Operation, kMaxQ> ops{};
    std::size_t roots_count = 1;
    for (std::size_t i = 0; i < q; ++i) {
        const auto op = input[2 + 4 * i], a = input[3 + 4 * i], b = input[4 + 4 * i], c = input[5 + 4 * i];
        if (op == 0) {
            if (a < 0 || static_cast<std::size_t>(a) >= roots_count || b < 1 || b > kDomain || c < 1 || c > 10) return -1;
        } else if (op == 1) {
            if (a < 0 || static_cast<std::size_t>(a) >= roots_count || b < 1 || c < b || c > kDomain || roots_count >= kMaxRoots) return -1;
            ++roots_count;
        } else if (op == 2) {
            if (a < 0 || static_cast<std::size_t>(a) >= roots_count || b < 0 || static_cast<std::size_t>(b) >= roots_count || a == b || c != 0) return -1;
        } else if (op == 3) {
            if (a < 0 || static_cast<std::size_t>(a) >= roots_count || b < 1 || c < b || c > kDomain) return -1;
        } else if (op == 4) {
            if (a < 0 || static_cast<std::size_t>(a) >= roots_count || b < 1 || b > kMaxQ * 10 || c != 0) return -1;
        } else return -1;
        ops[i] = {op, a, b, c};
    }
    std::array<Node, kMaxNodes> nodes{};
    std::array<int, kMaxRoots> roots{};
    std::array<std::uint8_t, kMaxOutput> staged{};
    int used = 1;
    std::size_t root_count = 1, bytes = 0;
    for (std::size_t i = 0; i < q; ++i) {
        const auto item = ops[i];
        const auto a = static_cast<std::size_t>(item.a);
        if (item.op == 0) {
            const int updated = insert(nodes, used, roots[a], 1, kDomain, static_cast<int>(item.b), static_cast<int>(item.c));
            if (updated < 0) return -1;
            roots[a] = updated;
        } else if (item.op == 1) {
            int moved = 0;
            const int remain = split(nodes, used, roots[a], 1, kDomain, static_cast<int>(item.b), static_cast<int>(item.c), moved);
            if (remain < 0) return -1;
            roots[a] = remain; roots[root_count++] = moved;
        } else if (item.op == 2) {
            const auto b = static_cast<std::size_t>(item.b);
            roots[a] = merge_nodes(nodes, roots[a], roots[b], 1, kDomain); roots[b] = 0;
        } else if (item.op == 3) {
            pack_i64(staged, bytes, range_sum(nodes, roots[a], 1, kDomain, static_cast<int>(item.b), static_cast<int>(item.c))); bytes += 8;
        } else {
            pack_i64(staged, bytes, kth(nodes, roots[a], 1, kDomain, item.b)); bytes += 8;
        }
    }
    if (output == nullptr || capacity < bytes) return -2;
    for (std::size_t i = 0; i < bytes; ++i) output[i] = staged[i];
    return static_cast<std::int64_t>(bytes);
}
