#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MaxN = 8, MaxM = 28, MaxInput = 90;
bool edge_before(std::size_t a, std::size_t b, const std::array<std::int64_t, MaxM>& u,
                 const std::array<std::int64_t, MaxM>& v,
                 const std::array<std::int64_t, MaxM>& w) {
    return w[a] < w[b] || (w[a] == w[b] && u[a] < u[b]) ||
           (w[a] == w[b] && u[a] == u[b] && v[a] < v[b]);
}
}

extern "C" std::int64_t baswana_sen_weighted_spanner(
    const std::int64_t* input, std::size_t length,
    std::uint8_t* output, std::size_t capacity) noexcept {
    if (!input || length < 3 || length > MaxInput) return -1;
    const auto n64 = input[0], m64 = input[1], k = input[2];
    if (n64 < 2 || n64 > static_cast<std::int64_t>(MaxN) || m64 < 0 ||
        m64 > static_cast<std::int64_t>(MaxM) || k < 2 || k > 3) return -1;
    const auto n = static_cast<std::size_t>(n64), m = static_cast<std::size_t>(m64);
    const auto rounds = static_cast<std::size_t>(k - 1);
    if (length != 3 + rounds + 3 * m) return -1;
    std::array<std::int64_t, MaxN> masks{};
    for (std::size_t r = 0; r < rounds; ++r) {
        masks[r] = input[3 + r];
        if (masks[r] < 0 || masks[r] >= (std::int64_t{1} << n)) return -1;
    }
    std::array<std::int64_t, MaxM> edge_u{}, edge_v{}, edge_w{};
    std::array<bool, MaxM> active{}, selected{};
    const auto offset = 3 + rounds;
    for (std::size_t e = 0; e < m; ++e) {
        edge_u[e] = input[offset + 3 * e]; edge_v[e] = input[offset + 3 * e + 1];
        edge_w[e] = input[offset + 3 * e + 2];
        if (edge_u[e] < 0 || edge_v[e] <= edge_u[e] || edge_v[e] >= n64 ||
            edge_w[e] < 1 || edge_w[e] > 32) return -1;
        for (std::size_t p = 0; p < e; ++p)
            if (edge_u[p] == edge_u[e] && edge_v[p] == edge_v[e]) return -1;
        active[e] = true;
    }
    if (!output || capacity < m) return -2;

    std::array<int, MaxN> cluster{}, next_cluster{};
    for (std::size_t v = 0; v < n; ++v) cluster[v] = static_cast<int>(v);
    for (std::size_t r = 0; r < rounds; ++r) {
        std::array<bool, MaxN> sampled{};
        std::array<bool, MaxM> remove{};
        std::array<std::array<std::size_t, MaxN>, MaxN> group_best{};
        for (auto& row : group_best) row.fill(m);
        next_cluster.fill(-1);
        for (std::size_t v = 0; v < n; ++v) {
            const int center = cluster[v];
            if (center >= 0 && ((masks[r] >> center) & 1) != 0) sampled[center] = true;
        }
        for (std::size_t v = 0; v < n; ++v)
            if (cluster[v] >= 0 && sampled[cluster[v]]) next_cluster[v] = cluster[v];
        for (std::size_t e = 0; e < m; ++e) if (active[e]) {
            const auto u = static_cast<std::size_t>(edge_u[e]);
            const auto v = static_cast<std::size_t>(edge_v[e]);
            if (cluster[v] >= 0 && (group_best[u][cluster[v]] == m || edge_before(e, group_best[u][cluster[v]], edge_u, edge_v, edge_w))) group_best[u][cluster[v]] = e;
            if (cluster[u] >= 0 && (group_best[v][cluster[u]] == m || edge_before(e, group_best[v][cluster[u]], edge_u, edge_v, edge_w))) group_best[v][cluster[u]] = e;
        }
        for (std::size_t v = 0; v < n; ++v) {
            const int old_center = cluster[v];
            if (old_center < 0 || sampled[old_center]) continue;
            std::size_t best_sampled = m;
            for (std::size_t c = 0; c < n; ++c)
                if (sampled[c] && group_best[v][c] != m &&
                    (best_sampled == m || edge_before(group_best[v][c], best_sampled, edge_u, edge_v, edge_w)))
                    best_sampled = group_best[v][c];
            if (best_sampled == m) {
                for (std::size_t c = 0; c < n; ++c) if (group_best[v][c] != m) {
                    selected[group_best[v][c]] = true;
                    for (std::size_t e = 0; e < m; ++e) if (active[e]) {
                        const auto u = static_cast<std::size_t>(edge_u[e]), w = static_cast<std::size_t>(edge_v[e]);
                        if ((u == v && cluster[w] == static_cast<int>(c)) || (w == v && cluster[u] == static_cast<int>(c))) remove[e] = true;
                    }
                }
                continue;
            }
            const auto edge = best_sampled;
            const auto u = static_cast<std::size_t>(edge_u[edge]), w = static_cast<std::size_t>(edge_v[edge]);
            const int landing = cluster[u == v ? w : u];
            next_cluster[v] = landing;
            selected[edge] = true;
            for (std::size_t c = 0; c < n; ++c) if (group_best[v][c] != m) {
                const auto least = group_best[v][c];
                const bool take = static_cast<int>(c) == landing || edge_w[least] < edge_w[edge];
                if (static_cast<int>(c) != landing && edge_w[least] < edge_w[edge]) selected[least] = true;
                if (take) for (std::size_t e = 0; e < m; ++e) if (active[e]) {
                    const auto a = static_cast<std::size_t>(edge_u[e]), b = static_cast<std::size_t>(edge_v[e]);
                    if ((a == v && cluster[b] == static_cast<int>(c)) || (b == v && cluster[a] == static_cast<int>(c))) remove[e] = true;
                }
            }
        }
        for (std::size_t e = 0; e < m; ++e) if (remove[e]) active[e] = false;
        for (std::size_t e = 0; e < m; ++e) if (active[e]) {
            const auto u = static_cast<std::size_t>(edge_u[e]), v = static_cast<std::size_t>(edge_v[e]);
            if (next_cluster[u] >= 0 && next_cluster[u] == next_cluster[v]) active[e] = false;
        }
        cluster = next_cluster;
    }
    std::array<std::array<std::size_t, MaxN>, MaxN> group_best{};
    for (auto& row : group_best) row.fill(m);
    for (std::size_t e = 0; e < m; ++e) if (active[e]) {
        const auto u = static_cast<std::size_t>(edge_u[e]), v = static_cast<std::size_t>(edge_v[e]);
        if (cluster[v] >= 0 && (group_best[u][cluster[v]] == m || edge_before(e, group_best[u][cluster[v]], edge_u, edge_v, edge_w))) group_best[u][cluster[v]] = e;
        if (cluster[u] >= 0 && (group_best[v][cluster[u]] == m || edge_before(e, group_best[v][cluster[u]], edge_u, edge_v, edge_w))) group_best[v][cluster[u]] = e;
    }
    for (std::size_t v = 0; v < n; ++v) if (cluster[v] >= 0)
        for (std::size_t c = 0; c < n; ++c) if (group_best[v][c] != m) selected[group_best[v][c]] = true;
    for (std::size_t e = 0; e < m; ++e) output[e] = selected[e] ? 1 : 0;
    return static_cast<std::int64_t>(m);
}
