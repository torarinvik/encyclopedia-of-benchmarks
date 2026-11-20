#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_NODES = 256;
constexpr std::size_t MAX_QUERIES = 1024;
constexpr std::size_t MAX_ARCS = 2 * (MAX_NODES - 1);
constexpr std::size_t MAX_INPUT = 4 + 2 * (MAX_NODES - 1) + 2 * MAX_QUERIES;

std::uint32_t lowbit(std::uint32_t x) { return x & (0u - x); }

std::uint32_t highbit(std::uint32_t x) {
    std::uint32_t result = 0;
    while (x != 0) { result = x; x >>= 1; }
    return result;
}
}

extern "C" std::int64_t schieber_vishkin_lca(const std::int64_t *input, std::size_t length,
    std::uint8_t *output, std::size_t output_capacity) {
    if (input == nullptr || length < 4 || length > MAX_INPUT + 1) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(MAX_NODES)) return -1;
    const std::size_t n = static_cast<std::size_t>(input[0]);
    if (input[1] < 0 || input[1] >= static_cast<std::int64_t>(n) ||
        input[2] != static_cast<std::int64_t>(n - 1) || input[3] < 0 ||
        input[3] > static_cast<std::int64_t>(MAX_QUERIES)) return -1;
    const std::size_t m = static_cast<std::size_t>(input[2]);
    const std::size_t q = static_cast<std::size_t>(input[3]);
    const std::size_t query_offset = 4 + 2 * m;
    if (length != query_offset + 2 * q) return -1;
    const std::size_t root = static_cast<std::size_t>(input[1]);

    int head[MAX_NODES], arc_to[MAX_ARCS], arc_next[MAX_ARCS];
    int parent[MAX_NODES], order[MAX_NODES], stack_node[MAX_NODES], stack_arc[MAX_NODES];
    std::size_t preorder[MAX_NODES];
    std::uint32_t inlabel[MAX_NODES], ascendant[MAX_NODES];
    int path_head[MAX_NODES];
    std::uint8_t answers[MAX_QUERIES];
    for (std::size_t i = 0; i < n; ++i) { head[i] = -1; parent[i] = -2; }

    std::size_t arcs = 0;
    for (std::size_t edge = 0; edge < m; ++edge) {
        const std::int64_t a64 = input[4 + 2 * edge], b64 = input[5 + 2 * edge];
        if (a64 < 0 || a64 >= static_cast<std::int64_t>(n) || b64 < 0 ||
            b64 >= static_cast<std::int64_t>(n) || a64 == b64) return -1;
        const std::size_t a = static_cast<std::size_t>(a64), b = static_cast<std::size_t>(b64);
        arc_to[arcs] = static_cast<int>(b); arc_next[arcs] = head[a]; head[a] = static_cast<int>(arcs++);
        arc_to[arcs] = static_cast<int>(a); arc_next[arcs] = head[b]; head[b] = static_cast<int>(arcs++);
    }
    for (std::size_t query = 0; query < q; ++query) {
        for (std::size_t side = 0; side < 2; ++side) {
            const std::int64_t node = input[query_offset + 2 * query + side];
            if (node < 0 || node >= static_cast<std::int64_t>(n)) return -1;
        }
    }

    std::size_t reached = 1, top = 1;
    parent[root] = -1; preorder[root] = 1; order[0] = static_cast<int>(root);
    stack_node[0] = static_cast<int>(root); stack_arc[0] = head[root];
    while (top != 0) {
        const std::size_t slot = top - 1;
        const std::size_t node = static_cast<std::size_t>(stack_node[slot]);
        const int arc = stack_arc[slot];
        if (arc < 0) { --top; continue; }
        stack_arc[slot] = arc_next[arc];
        const std::size_t neighbor = static_cast<std::size_t>(arc_to[arc]);
        if (static_cast<int>(neighbor) == parent[node]) continue;
        if (parent[neighbor] != -2) return -1;
        parent[neighbor] = static_cast<int>(node);
        preorder[neighbor] = reached + 1;
        order[reached++] = static_cast<int>(neighbor);
        stack_node[top] = static_cast<int>(neighbor); stack_arc[top] = head[neighbor]; ++top;
    }
    if (reached != n) return -1;
    if (output_capacity < q || (q != 0 && output == nullptr)) return -2;

    for (std::size_t node = 0; node < n; ++node) inlabel[node] = static_cast<std::uint32_t>(preorder[node]);
    for (std::size_t i = n; i > 1; --i) {
        const std::size_t node = static_cast<std::size_t>(order[i - 1]);
        const std::size_t p = static_cast<std::size_t>(parent[node]);
        if (lowbit(inlabel[p]) < lowbit(inlabel[node])) inlabel[p] = inlabel[node];
    }
    for (std::size_t i = 0; i < n; ++i) {
        const std::size_t node = static_cast<std::size_t>(order[i]);
        if (parent[node] < 0) {
            ascendant[node] = lowbit(inlabel[node]);
            path_head[preorder[node] - 1] = static_cast<int>(node);
        } else {
            const std::size_t p = static_cast<std::size_t>(parent[node]);
            ascendant[node] = ascendant[p] | lowbit(inlabel[node]);
            path_head[preorder[node] - 1] = inlabel[node] != inlabel[p]
                ? static_cast<int>(p) : path_head[preorder[p] - 1];
        }
    }

    for (std::size_t query = 0; query < q; ++query) {
        const std::size_t u = static_cast<std::size_t>(input[query_offset + 2 * query]);
        const std::size_t v = static_cast<std::size_t>(input[query_offset + 2 * query + 1]);
        const std::uint32_t lu = lowbit(inlabel[u]), lv = lowbit(inlabel[v]);
        std::uint32_t mask = highbit((inlabel[u] ^ inlabel[v]) | lu | lv) - 1u;
        const std::uint32_t j = lowbit(ascendant[u] & ascendant[v] & ~mask);
        if (j == 0) return -1;
        std::size_t x = u, y = v;
        if (j != lu) {
            mask = highbit(ascendant[u] & (j - 1u)) - 1u;
            const std::size_t index = ((preorder[u] & ~static_cast<std::size_t>(mask)) |
                (static_cast<std::size_t>(mask) + 1u)) - 1u;
            x = static_cast<std::size_t>(path_head[index]);
        }
        if (j != lv) {
            mask = highbit(ascendant[v] & (j - 1u)) - 1u;
            const std::size_t index = ((preorder[v] & ~static_cast<std::size_t>(mask)) |
                (static_cast<std::size_t>(mask) + 1u)) - 1u;
            y = static_cast<std::size_t>(path_head[index]);
        }
        answers[query] = static_cast<std::uint8_t>(preorder[x] < preorder[y] ? x : y);
    }
    for (std::size_t query = 0; query < q; ++query) output[query] = answers[query];
    return static_cast<std::int64_t>(q);
}
