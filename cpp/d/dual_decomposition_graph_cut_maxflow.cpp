#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int max_n = 6, max_m = 10, stride = 8;
constexpr std::int64_t offset = 7000;
constexpr std::array<std::int64_t, 9> scales{0, 2, 2, 6, 12, 60, 60, 420, 840};

bool member(int owner, int side) { return owner == side || owner == 2; }

std::int64_t solve(int side, int n, int m, const std::array<int, max_n>& owner,
                   const std::array<std::int64_t, max_n>& source_cap,
                   const std::array<std::int64_t, max_n>& sink_cap,
                   const std::array<int, max_m>& eu, const std::array<int, max_m>& ev,
                   const std::array<std::int64_t, max_m>& uv,
                   const std::array<std::int64_t, max_m>& vu,
                   const std::array<std::int64_t, max_n>& lambda,
                   std::int64_t scale, std::array<std::int64_t, max_n>& labels) {
    const int source = n, sink = n + 1, size = n + 2;
    std::array<std::array<std::int64_t, stride>, stride> residual{};
    std::int64_t constant = 0, flow = 0, source_sum = 0, lambda_sum = 0;
    for (int u = 0; u < n; ++u) if (member(owner[u], side)) {
        const auto factor = owner[u] == 2 ? scale / 2 : scale;
        residual[source][u] += source_cap[u] * factor;
        residual[u][sink] += sink_cap[u] * factor;
    }
    for (int u = 0; u < n; ++u) source_sum += source_cap[u];
    for (int u = 0; u < n; ++u) if (owner[u] == 2) lambda_sum += lambda[u] < 0 ? -lambda[u] : lambda[u];
    for (int i = 0; i < m; ++i) if (member(owner[eu[i]], side) && member(owner[ev[i]], side)) {
        const auto factor = owner[eu[i]] == 2 && owner[ev[i]] == 2 ? scale / 2 : scale;
        residual[eu[i]][ev[i]] += uv[i] * factor;
        residual[ev[i]][eu[i]] += vu[i] * factor;
    }
    for (int u = 0; u < n; ++u) if (owner[u] == 2) {
        const auto q = side == 0 ? lambda[u] : -lambda[u];
        if (q >= 0) residual[source][u] += q;
        else { residual[u][sink] += -q; constant += q; }
    }
    for (;;) {
        std::array<int, stride> parent;
        parent.fill(-1);
        std::array<int, stride> queue{};
        parent[source] = source;
        int head = 0, tail = 0;
        queue[tail++] = source;
        while (head < tail && parent[sink] < 0) {
            const int u = queue[head++];
            for (int v = 0; v < size; ++v) if (parent[v] < 0 && residual[u][v] > 0) {
                parent[v] = u; queue[tail++] = v;
                if (v == sink) break;
            }
        }
        if (parent[sink] < 0) {
            for (int u = 0; u < n; ++u) labels[u] = member(owner[u], side) && parent[u] < 0 ? 1 : 0;
            return flow + constant;
        }
        auto amount = source_sum * scale + lambda_sum + 1;
        for (int v = sink; v != source; v = parent[v]) if (residual[parent[v]][v] < amount) amount = residual[parent[v]][v];
        for (int v = sink; v != source; v = parent[v]) {
            const int u = parent[v]; residual[u][v] -= amount; residual[v][u] += amount;
        }
        flow += amount;
    }
}
}

extern "C" std::int64_t dual_decomposition_graph_cut_maxflow(const std::int64_t* input, std::size_t length) noexcept {
    if (input == nullptr || length < 4 || length > 63) return -1;
    const auto rn = input[0], rm = input[1], ro = input[2], rt = input[3];
    if (rn < 3 || rn > max_n || rm < 0 || rm > max_m || ro < 1 || ro > 3 || rt < 1 || rt > 8 ||
        length != 4 + 3 * static_cast<std::size_t>(rn) + 4 * static_cast<std::size_t>(rm)) return -1;
    const int n = static_cast<int>(rn), m = static_cast<int>(rm), overlap = static_cast<int>(ro), rounds = static_cast<int>(rt);
    std::array<int, max_n> owner{}; std::array<int, 3> counts{};
    std::size_t at = 4;
    for (int u = 0; u < n; ++u) {
        const auto x = input[at++]; if (x < 0 || x > 2) return -1;
        owner[u] = static_cast<int>(x); ++counts[static_cast<std::size_t>(x)];
    }
    if (counts[0] == 0 || counts[1] == 0 || counts[2] != overlap) return -1;
    std::array<std::int64_t, max_n> source_cap{}, sink_cap{};
    for (int u = 0; u < n; ++u) { source_cap[u] = input[at++]; if (source_cap[u] < 0 || source_cap[u] > 6 || source_cap[u] % 2 != 0) return -1; }
    for (int u = 0; u < n; ++u) { sink_cap[u] = input[at++]; if (sink_cap[u] < 0 || sink_cap[u] > 6 || sink_cap[u] % 2 != 0) return -1; }
    std::array<int, max_m> eu{}, ev{}; std::array<std::int64_t, max_m> uv{}, vu{};
    for (int i = 0; i < m; ++i) {
        const auto u = input[at++], v = input[at++], c = input[at++], d = input[at++];
        if (u < 0 || u >= n || v < 0 || v >= n || u == v ||
            (owner[u] == 0 && owner[v] == 1) || (owner[u] == 1 && owner[v] == 0) ||
            c < 0 || c > 6 || c % 2 != 0 || d < 0 || d > 6 || d % 2 != 0) return -1;
        eu[i] = static_cast<int>(u); ev[i] = static_cast<int>(v); uv[i] = c; vu[i] = d;
    }
    const auto scale = scales[static_cast<std::size_t>(rounds)];
    std::array<std::int64_t, max_n> lambda{}, labels_m{}, labels_n{};
    std::int64_t dual_scaled = 0; bool agreement = false;
    for (int iteration = 1; iteration <= rounds; ++iteration) {
        const auto energy_m = solve(0,n,m,owner,source_cap,sink_cap,eu,ev,uv,vu,lambda,scale,labels_m);
        const auto energy_n = solve(1,n,m,owner,source_cap,sink_cap,eu,ev,uv,vu,lambda,scale,labels_n);
        dual_scaled = energy_m + energy_n; agreement = true;
        for (int u = 0; u < n; ++u) if (owner[u] == 2 && labels_m[u] != labels_n[u]) agreement = false;
        if (agreement || iteration == rounds) break;
        const auto step = scale / iteration;
        for (int u = 0; u < n; ++u) if (owner[u] == 2) lambda[u] += step * (labels_m[u] - labels_n[u]);
    }
    return 2 * (dual_scaled + offset) + static_cast<std::int64_t>(agreement);
}
