#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_n = 8, max_edges = 28, walk_limit = 64;
constexpr std::size_t max_input = 4 + 2 * max_edges + walk_limit * (max_n - 1);
void write_i64(std::uint8_t *out, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t b = 0; b < 8; ++b) out[offset + b] = static_cast<std::uint8_t>(bits >> (8 * b));
}
}

extern "C" std::int64_t wilson_uniform_spanning_tree(const std::int64_t *input,
        std::size_t length, std::uint8_t *output, std::size_t capacity) {
    if (input == nullptr || length < 4 || length > max_input + 1) return -1;
    const auto n0 = input[0], m0 = input[1], root0 = input[2];
    if (n0 < 1 || n0 > static_cast<std::int64_t>(max_n) || m0 < 0 || m0 > static_cast<std::int64_t>(max_edges)) return -1;
    const auto n = static_cast<std::size_t>(n0), m = static_cast<std::size_t>(m0);
    if (root0 < 0 || root0 >= n0) return -1;
    const auto root = static_cast<std::size_t>(root0), q_at = 3 + 2 * m;
    if (length <= q_at) return -1;
    const auto q0 = input[q_at];
    if (q0 < 0 || q0 > static_cast<std::int64_t>(walk_limit * (n - 1))) return -1;
    const auto q = static_cast<std::size_t>(q0);
    if (length != q_at + 1 + q) return -1;

    std::array<std::array<std::size_t, max_n - 1>, max_n> neighbors{};
    std::array<std::size_t, max_n> degree{};
    std::int64_t prev_u = -1, prev_v = -1;
    for (std::size_t e = 0; e < m; ++e) {
        const auto u0 = input[3 + 2 * e], v0 = input[4 + 2 * e];
        if (u0 < 0 || u0 >= v0 || v0 >= n0) return -1;
        if (e && (u0 < prev_u || (u0 == prev_u && v0 <= prev_v))) return -1;
        prev_u = u0; prev_v = v0;
        const auto u = static_cast<std::size_t>(u0), v = static_cast<std::size_t>(v0);
        neighbors[u][degree[u]++] = v; neighbors[v][degree[v]++] = u;
    }
    for (std::size_t i = 0; i < q; ++i) if (input[q_at + 1 + i] < 0 || input[q_at + 1 + i] > static_cast<std::int64_t>(max_n - 2)) return -1;

    std::array<bool, max_n> seen{};
    std::array<std::size_t, max_n> queue{};
    std::size_t head = 0, tail = 0;
    seen[root] = true; queue[tail++] = root;
    while (head < tail) {
        const auto at = queue[head++];
        for (std::size_t k = 0; k < degree[at]; ++k) {
            const auto to = neighbors[at][k];
            if (!seen[to]) { seen[to] = true; queue[tail++] = to; }
        }
    }
    for (std::size_t i = 0; i < n; ++i) if (!seen[i]) return -1;

    std::array<bool, max_n> in_tree{};
    std::array<std::int64_t, max_n> successor{};
    successor.fill(-1); in_tree[root] = true;
    std::size_t cursor = 0;
    for (std::size_t start = 0; start < n; ++start) {
        if (in_tree[start]) continue;
        std::size_t current = start, steps = 0;
        while (!in_tree[current]) {
            if (steps >= walk_limit || cursor >= q) return -1;
            const auto choice = static_cast<std::size_t>(input[q_at + 1 + cursor]);
            if (choice >= degree[current]) return -1;
            successor[current] = static_cast<std::int64_t>(neighbors[current][choice]);
            current = static_cast<std::size_t>(successor[current]); ++cursor; ++steps;
        }
        current = start;
        while (!in_tree[current]) { in_tree[current] = true; current = static_cast<std::size_t>(successor[current]); }
    }
    if (cursor != q) return -1;
    const auto required = 16 * (n - 1);
    if ((required && output == nullptr) || capacity < required) return -2;
    std::size_t offset = 0;
    for (std::size_t child = 0; child < n; ++child) if (child != root) {
        write_i64(output, offset, static_cast<std::int64_t>(child)); offset += 8;
        write_i64(output, offset, successor[child]); offset += 8;
    }
    return static_cast<std::int64_t>(required);
}
