// Clean-room bounded GBBS Tarjan-Vishkin biconnectivity profile.
#include <cstddef>
#include <cstdint>
#include <limits>

namespace {
constexpr std::size_t N = 12, M = 24, INPUT = 2 + 2 * M;
using Matrix = bool[N][N];

bool tree_edge(std::size_t u, std::size_t v, const std::size_t* parent) {
    return parent[u] == v || parent[v] == u;
}
bool critical_edge(std::size_t u, std::size_t v, const std::size_t* parent,
                   const bool* critical) {
    if (parent[u] == v) return critical[u];
    if (parent[v] == u) return critical[v];
    return false;
}
void parents_bfs(std::size_t n, const Matrix& adj, std::size_t* parent, bool* seen) {
    std::size_t frontier[N], next[N], candidate[N];
    for (std::size_t root = 0; root < n; ++root) {
        if (seen[root]) continue;
        std::size_t count = 1;
        frontier[0] = root;
        parent[root] = root;
        seen[root] = true;
        while (count != 0) {
            bool has[N] = {};
            for (std::size_t i = 0; i < count; ++i) {
                const auto v = frontier[i];
                for (std::size_t u = 0; u < n; ++u) if (adj[v][u] && !seen[u]) {
                    if (!has[u] || v < candidate[u]) candidate[u] = v;
                    has[u] = true;
                }
            }
            std::size_t next_count = 0;
            for (std::size_t u = 0; u < n; ++u) if (has[u]) {
                parent[u] = candidate[u];
                seen[u] = true;
                next[next_count++] = u;
            }
            for (std::size_t i = 0; i < next_count; ++i) frontier[i] = next[i];
            count = next_count;
        }
    }
}
void preorder(std::size_t n, const std::size_t* parent, std::size_t* pn,
              std::size_t* order, std::size_t* size) {
    std::size_t stack[N], global = 0;
    for (std::size_t root = 0; root < n; ++root) if (parent[root] == root) {
        std::size_t top = 0, count = 0, begin = global;
        stack[top++] = root;
        while (top != 0) {
            const auto v = stack[--top];
            pn[v] = count++;
            order[global++] = v;
            for (std::size_t child = n; child-- > 0;)
                if (child != v && parent[child] == v) stack[top++] = child;
        }
        for (std::size_t i = global; i-- > begin;) {
            const auto v = order[i];
            if (parent[v] != v) size[parent[v]] += size[v];
        }
    }
}
} // namespace

extern "C" std::int64_t gbbs_biconnectivity(const std::int64_t* input,
        std::size_t length, std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length < 2 || length > INPUT) return -1;
    const auto n64 = input[0], m64 = input[1];
    if (n64 < 1 || n64 > static_cast<std::int64_t>(N) || m64 < 0 ||
        m64 > static_cast<std::int64_t>(M) || length != 2 + 2 * static_cast<std::size_t>(m64)) return -1;
    const auto n = static_cast<std::size_t>(n64), m = static_cast<std::size_t>(m64);
    Matrix adj = {};
    for (std::size_t e = 0; e < m; ++e) {
        const auto u64 = input[2 + 2 * e], v64 = input[3 + 2 * e];
        if (u64 < 0 || v64 <= u64 || v64 >= n64) return -1;
        const auto u = static_cast<std::size_t>(u64), v = static_cast<std::size_t>(v64);
        if (adj[u][v]) return -1;
        adj[u][v] = adj[v][u] = true;
    }
    if (output == nullptr || capacity < m) return -2;
    std::size_t parent[N], pn[N], order[N], size[N], low[N], high[N], comp[N], queue[N];
    bool seen[N] = {}, critical[N] = {};
    for (std::size_t v = 0; v < n; ++v) {
        parent[v] = v; size[v] = 1;
    }
    parents_bfs(n, adj, parent, seen);
    preorder(n, parent, pn, order, size);
    for (std::size_t v = 0; v < n; ++v) { low[v] = pn[v]; high[v] = pn[v] + size[v] - 1; }
    for (std::size_t e = 0; e < m; ++e) {
        const auto u = static_cast<std::size_t>(input[2 + 2 * e]);
        const auto v = static_cast<std::size_t>(input[3 + 2 * e]);
        if (!tree_edge(u, v, parent)) {
            if (pn[u] < low[v]) low[v] = pn[u]; else if (pn[u] > high[v]) high[v] = pn[u];
            if (pn[v] < low[u]) low[u] = pn[v]; else if (pn[v] > high[u]) high[u] = pn[v];
        }
    }
    for (std::size_t i = n; i-- > 0;) {
        const auto v = order[i];
        if (parent[v] != v) {
            const auto p = parent[v];
            if (low[v] < low[p]) low[p] = low[v];
            if (high[v] > high[p]) high[p] = high[v];
        }
    }
    for (std::size_t v = 0; v < n; ++v) {
        const auto p = parent[v];
        if (v != p && low[v] >= pn[p] && high[v] < pn[p] + size[p]) critical[v] = true;
    }
    for (std::size_t v = 0; v < n; ++v) comp[v] = std::numeric_limits<std::size_t>::max();
    for (std::size_t root = 0; root < n; ++root) if (comp[root] == std::numeric_limits<std::size_t>::max()) {
        std::size_t head = 0, tail = 0;
        comp[root] = root; queue[tail++] = root;
        while (head < tail) {
            const auto v = queue[head++];
            for (std::size_t u = 0; u < n; ++u)
                if (adj[v][u] && !critical_edge(v, u, parent, critical) &&
                    comp[u] == std::numeric_limits<std::size_t>::max()) {
                    comp[u] = root; queue[tail++] = u;
                }
        }
    }
    std::size_t raw[M];
    for (std::size_t e = 0; e < m; ++e) {
        const auto u = static_cast<std::size_t>(input[2 + 2 * e]);
        const auto v = static_cast<std::size_t>(input[3 + 2 * e]);
        if (parent[u] == v && critical[u]) raw[e] = comp[u];
        else if (parent[v] == u && critical[v]) raw[e] = comp[v];
        else raw[e] = comp[u];
    }
    for (std::size_t e = 0; e < m; ++e) {
        std::size_t label = m;
        for (std::size_t j = 0; j < m; ++j)
            if (raw[j] == raw[e] && j < label) label = j;
        output[e] = static_cast<std::uint8_t>(label);
    }
    return static_cast<std::int64_t>(m);
}
