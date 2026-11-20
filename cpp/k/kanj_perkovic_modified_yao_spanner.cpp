// Clean-room bounded Kanj--Perkovic modified-Yao selection pass.
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int N = 16, M = 42, K = 14, D = 84;
constexpr std::size_t VALID = 312, PARSEABLE = 313;
}

extern "C" std::int64_t kanj_perkovic_modified_yao_spanner(
    const std::int64_t* input, std::size_t length) {
    if (input == nullptr || length < 2 || length > PARSEABLE) return -1;
    const auto n64 = input[0], m64 = input[1];
    if (n64 < 3 || n64 > N || m64 < n64 - 1 || m64 > M ||
        m64 > 3 * n64 - 6 || length != 2 + static_cast<std::size_t>(n64) +
        7 * static_cast<std::size_t>(m64) || length > VALID) return -1;
    const int n = static_cast<int>(n64), m = static_cast<int>(m64), dcount = 2 * static_cast<int>(m64);
    std::array<int, M> eu{}, ev{}, cu{}, cv{};
    std::array<std::int64_t, M> weight{};
    std::array<std::array<bool, N>, N> adjacent{};
    std::array<int, N> expected_degree{};
    std::array<int, D> source{}, cone{};
    for (int e = 0; e < m; ++e) {
        const std::size_t p = 2 + 5 * static_cast<std::size_t>(e);
        const auto u = input[p], v = input[p + 1], w = input[p + 2];
        const auto a = input[p + 3], b = input[p + 4];
        if (u < 0 || u >= v || v >= n || w < 1 || w > INT64_C(1000000000000) ||
            a < 0 || a >= K || b < 0 || b >= K) return -1;
        if (e && (u < eu[e - 1] || (u == eu[e - 1] && v <= ev[e - 1]))) return -1;
        eu[e] = static_cast<int>(u); ev[e] = static_cast<int>(v);
        weight[e] = w; cu[e] = static_cast<int>(a); cv[e] = static_cast<int>(b);
        adjacent[u][v] = adjacent[v][u] = true;
        ++expected_degree[u]; ++expected_degree[v];
        source[2 * e] = static_cast<int>(u); source[2 * e + 1] = static_cast<int>(v);
        cone[2 * e] = static_cast<int>(a); cone[2 * e + 1] = static_cast<int>(b);
    }
    std::array<int, D> rotation{}, position{};
    std::array<int, N> row_start{}, degree{};
    std::array<std::array<int, K>, N> first{}, after{};
    std::array<bool, D> seen{};
    for (int v = 0; v < n; ++v) for (int c = 0; c < K; ++c) first[v][c] = after[v][c] = -1;
    std::size_t cursor = 2 + 5 * static_cast<std::size_t>(m), used = 0;
    for (int v = 0; v < n; ++v) {
        const auto d64 = input[cursor++];
        if (d64 != expected_degree[v] || d64 < 1 || d64 > D) return -1;
        const int d = static_cast<int>(d64);
        row_start[v] = static_cast<int>(used); degree[v] = d;
        int previous = -1;
        for (int j = 0; j < d; ++j) {
            const auto raw = input[cursor++];
            if (raw < 0 || raw >= dcount) return -1;
            const int dart = static_cast<int>(raw), c = cone[dart];
            if (seen[dart] || source[dart] != v || c < previous) return -1;
            previous = c; seen[dart] = true;
            rotation[used] = dart; position[dart] = static_cast<int>(used);
            if (first[v][c] < 0) first[v][c] = static_cast<int>(used);
            after[v][c] = static_cast<int>(used + 1); ++used;
        }
    }
    if (cursor != length || used != static_cast<std::size_t>(dcount)) return -1;
    for (int d = 0; d < dcount; ++d) if (!seen[d]) return -1;
    std::array<bool, N> reached{};
    std::array<int, N> queue{};
    int head = 0, tail = 0; queue[tail++] = 0; reached[0] = true;
    while (head < tail) {
        const int u = queue[head++];
        for (int v = 0; v < n; ++v) if (adjacent[u][v] && !reached[v]) {
            reached[v] = true; queue[tail++] = v;
        }
    }
    if (tail != n) return -1;
    std::array<int, D> next_face{};
    std::array<bool, D> visited_face{};
    int faces = 0;
    for (int d = 0; d < dcount; ++d) {
        const int twin = d ^ 1, dest = source[twin];
        const int local = position[twin] - row_start[dest];
        next_face[d] = rotation[row_start[dest] + (local + degree[dest] - 1) % degree[dest]];
    }
    for (int d = 0; d < dcount; ++d) if (!visited_face[d]) {
        ++faces; int x = d;
        while (!visited_face[x]) { visited_face[x] = true; x = next_face[x]; }
        if (x != d) return -1;
    }
    if (n - m + faces != 2) return -1;

    std::array<bool, D> chosen{};
    for (int v = 0; v < n; ++v) for (int c = 0; c < K; ++c) {
        if (first[v][c] < 0) continue;
        int best = -1;
        for (int p = first[v][c]; p < after[v][c]; ++p) {
            const int dart = rotation[p], e = dart / 2;
            if (best < 0 || weight[e] < weight[best / 2] ||
                (weight[e] == weight[best / 2] && e < best / 2)) best = dart;
        }
        chosen[best] = true;
    }
    for (int v = 0; v < n; ++v) {
        int occupied = 0;
        for (int c = 0; c < K; ++c) occupied += first[v][c] >= 0;
        if (!occupied) continue;
        for (int start = 0; start < K; ++start) {
            if (first[v][start] >= 0 || first[v][(start + K - 1) % K] < 0) continue;
            int len = 0;
            while (len < K && first[v][(start + len) % K] < 0) ++len;
            if (len == 1) {
                const int cw_c = (start + K - 1) % K, ccw_c = (start + 1) % K;
                const int cw = rotation[after[v][cw_c] - 1], ccw = rotation[first[v][ccw_c]];
                if (chosen[cw]) chosen[ccw] = true;
                else if (chosen[ccw]) chosen[cw] = true;
                else {
                    const int a = cw / 2, b = ccw / 2;
                    chosen[(weight[a] < weight[b] || (weight[a] == weight[b] && a < b)) ? cw : ccw] = true;
                }
            } else {
                int cw_left = len / 2, ccw_left = (len + 1) / 2;
                for (int step = 1; step <= K && cw_left; ++step) {
                    const int c = (start - step + K) % K;
                    for (int p = after[v][c] - 1; p >= first[v][c] && cw_left; --p)
                        if (!chosen[rotation[p]]) { chosen[rotation[p]] = true; --cw_left; }
                }
                for (int step = len; step < len + K && ccw_left; ++step) {
                    const int c = (start + step) % K;
                    for (int p = first[v][c]; p >= 0 && p < after[v][c] && ccw_left; ++p)
                        if (!chosen[rotation[p]]) { chosen[rotation[p]] = true; --ccw_left; }
                }
            }
        }
    }
    std::uint64_t mask = 0;
    for (int e = 0; e < m; ++e) if (chosen[2 * e] && chosen[2 * e + 1]) mask |= UINT64_C(1) << e;
    return static_cast<std::int64_t>(mask);
}
