#include <array>
#include <algorithm>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int max_n = 8, max_m = 16, max_b = 4, stride = 10;

bool allowed_arc(int u, int v, int n, const std::array<int, 8>& allowed) {
    if (u < n && !allowed[static_cast<std::size_t>(u)]) return false;
    if (v < n && !allowed[static_cast<std::size_t>(v)]) return false;
    return v != n && u != n + 1;
}

void augment(std::array<std::int64_t, stride * stride>& residual, int n,
             const std::array<int, 8>& allowed) {
    const int source = n, sink = n + 1, size = n + 2;
    for (;;) {
        std::array<int, stride> parent;
        parent.fill(-1);
        std::array<int, stride> queue{};
        parent[static_cast<std::size_t>(source)] = source;
        int head = 0, tail = 0;
        queue[static_cast<std::size_t>(tail++)] = source;
        while (head < tail && parent[static_cast<std::size_t>(sink)] < 0) {
            const int u = queue[static_cast<std::size_t>(head++)];
            for (int v = 0; v < size; ++v) {
                const auto cell = static_cast<std::size_t>(u * stride + v);
                if (parent[static_cast<std::size_t>(v)] < 0 && residual[cell] > 0 && allowed_arc(u, v, n, allowed)) {
                    parent[static_cast<std::size_t>(v)] = u;
                    queue[static_cast<std::size_t>(tail++)] = v;
                    if (v == sink) break;
                }
            }
        }
        if (parent[static_cast<std::size_t>(sink)] < 0) return;
        std::int64_t amount = static_cast<std::int64_t>(n) * 7;
        for (int v = sink; v != source; v = parent[static_cast<std::size_t>(v)]) {
            const int u = parent[static_cast<std::size_t>(v)];
            amount = std::min(amount, residual[static_cast<std::size_t>(u * stride + v)]);
        }
        for (int v = sink; v != source; v = parent[static_cast<std::size_t>(v)]) {
            const int u = parent[static_cast<std::size_t>(v)];
            residual[static_cast<std::size_t>(u * stride + v)] -= amount;
            residual[static_cast<std::size_t>(v * stride + u)] += amount;
        }
    }
}
}

extern "C" std::int64_t adaptive_bottom_up_graph_cut_merging(const std::int64_t* input, std::size_t length) noexcept {
    if (input == nullptr || length < 3 || length > 92) return -1;
    const auto raw_n = input[0], raw_m = input[1], raw_b = input[2];
    if (raw_n < 2 || raw_n > max_n || raw_m < 0 || raw_m > max_m || raw_b < 1 || raw_b > max_b || raw_b > raw_n ||
        length != 3 + 3 * static_cast<std::size_t>(raw_n) + 4 * static_cast<std::size_t>(raw_m)) return -1;
    const int n = static_cast<int>(raw_n), m = static_cast<int>(raw_m), bcount = static_cast<int>(raw_b);
    std::array<int, max_n> block{};
    std::array<bool, max_b> seen{};
    std::array<std::int64_t, max_n> source_cap{}, sink_cap{};
    std::size_t at = 3;
    for (int u = 0; u < n; ++u) {
        const auto x = input[at++];
        if (x < 0 || x >= bcount) return -1;
        block[static_cast<std::size_t>(u)] = static_cast<int>(x);
        seen[static_cast<std::size_t>(x)] = true;
    }
    for (int b = 0; b < bcount; ++b) if (!seen[static_cast<std::size_t>(b)]) return -1;
    for (int u = 0; u < n; ++u) { auto& c = source_cap[static_cast<std::size_t>(u)]; c = input[at++]; if (c < 0 || c > 7) return -1; }
    for (int u = 0; u < n; ++u) { auto& c = sink_cap[static_cast<std::size_t>(u)]; c = input[at++]; if (c < 0 || c > 7) return -1; }

    std::array<int, max_m> eu{}, ev{}, ba{}, bb{};
    std::array<bool, max_m> cross{}, enabled{};
    std::array<std::int64_t, max_m> uv{}, vu{};
    std::array<std::int64_t, stride * stride> residual{};
    for (int u = 0; u < n; ++u) {
        residual[static_cast<std::size_t>(n * stride + u)] += source_cap[static_cast<std::size_t>(u)];
        residual[static_cast<std::size_t>(u * stride + n + 1)] += sink_cap[static_cast<std::size_t>(u)];
    }
    std::array<std::int64_t, max_b * max_b> potential{};
    std::array<bool, max_b * max_b> present{};
    for (int i = 0; i < m; ++i) {
        const auto ru = input[at++], rv = input[at++], rc = input[at++], rd = input[at++];
        if (ru < 0 || ru >= n || rv < 0 || rv >= n || ru == rv || rc < 0 || rc > 7 || rd < 0 || rd > 7) return -1;
        const int u = static_cast<int>(ru), v = static_cast<int>(rv);
        eu[static_cast<std::size_t>(i)] = u; ev[static_cast<std::size_t>(i)] = v;
        uv[static_cast<std::size_t>(i)] = rc; vu[static_cast<std::size_t>(i)] = rd;
        if (block[static_cast<std::size_t>(u)] == block[static_cast<std::size_t>(v)]) {
            residual[static_cast<std::size_t>(u * stride + v)] += rc;
            residual[static_cast<std::size_t>(v * stride + u)] += rd;
        } else {
            const int x = block[static_cast<std::size_t>(u)], y = block[static_cast<std::size_t>(v)];
            ba[static_cast<std::size_t>(i)] = std::min(x, y); bb[static_cast<std::size_t>(i)] = std::max(x, y);
            cross[static_cast<std::size_t>(i)] = rc != 0 || rd != 0;
            if (cross[static_cast<std::size_t>(i)]) present[static_cast<std::size_t>(ba[static_cast<std::size_t>(i)] * max_b + bb[static_cast<std::size_t>(i)])] = true;
        }
    }
    std::array<int, max_n> allowed{};
    for (int b = 0; b < bcount; ++b) {
        for (int u = 0; u < n; ++u) allowed[static_cast<std::size_t>(u)] = block[static_cast<std::size_t>(u)] == b;
        augment(residual, n, allowed);
    }
    std::array<int, max_n> tag{};
    for (int b = 0; b < bcount; ++b) {
        std::array<bool, stride> ss{}, tt{};
        std::array<int, stride> queue{};
        for (int u = 0; u < n; ++u) allowed[static_cast<std::size_t>(u)] = block[static_cast<std::size_t>(u)] == b;
        int head = 0, tail = 0; ss[static_cast<std::size_t>(n)] = true; queue[static_cast<std::size_t>(tail++)] = n;
        while (head < tail) { int u = queue[static_cast<std::size_t>(head++)]; for (int v = 0; v < n + 2; ++v)
            if (!ss[static_cast<std::size_t>(v)] && residual[static_cast<std::size_t>(u * stride + v)] > 0 && (u >= n || allowed[static_cast<std::size_t>(u)]) && (v >= n || allowed[static_cast<std::size_t>(v)])) { ss[static_cast<std::size_t>(v)] = true; queue[static_cast<std::size_t>(tail++)] = v; } }
        head = 0; tail = 0; tt[static_cast<std::size_t>(n + 1)] = true; queue[static_cast<std::size_t>(tail++)] = n + 1;
        while (head < tail) { int v = queue[static_cast<std::size_t>(head++)]; for (int u = 0; u < n + 2; ++u)
            if (!tt[static_cast<std::size_t>(u)] && residual[static_cast<std::size_t>(u * stride + v)] > 0 && (u >= n || allowed[static_cast<std::size_t>(u)]) && (v >= n || allowed[static_cast<std::size_t>(v)])) { tt[static_cast<std::size_t>(u)] = true; queue[static_cast<std::size_t>(tail++)] = u; } }
        for (int u = 0; u < n; ++u) if (allowed[static_cast<std::size_t>(u)]) tag[static_cast<std::size_t>(u)] = ss[static_cast<std::size_t>(u)] ? 1 : (tt[static_cast<std::size_t>(u)] ? 2 : 0);
    }
    for (int i = 0; i < m; ++i) if (cross[static_cast<std::size_t>(i)] && tag[static_cast<std::size_t>(eu[static_cast<std::size_t>(i)])] != tag[static_cast<std::size_t>(ev[static_cast<std::size_t>(i)])])
        potential[static_cast<std::size_t>(ba[static_cast<std::size_t>(i)] * max_b + bb[static_cast<std::size_t>(i)])] += (uv[static_cast<std::size_t>(i)] > 0) + (vu[static_cast<std::size_t>(i)] > 0);

    std::array<int, max_b * max_b> oa{}, ob{}; int order_n = 0;
    for (int a = 0; a < bcount; ++a) for (int b = a + 1; b < bcount; ++b) if (present[static_cast<std::size_t>(a * max_b + b)]) {
        int p = order_n++;
        while (p > 0) {
            int pa = oa[static_cast<std::size_t>(p - 1)], pb = ob[static_cast<std::size_t>(p - 1)];
            auto prior = potential[static_cast<std::size_t>(pa * max_b + pb)], current = potential[static_cast<std::size_t>(a * max_b + b)];
            if (prior > current || (prior == current && (pa < a || (pa == a && pb <= b)))) break;
            oa[static_cast<std::size_t>(p)] = pa; ob[static_cast<std::size_t>(p)] = pb; --p;
        }
        oa[static_cast<std::size_t>(p)] = a; ob[static_cast<std::size_t>(p)] = b;
    }
    std::array<int, max_b> parent{0, 1, 2, 3};
    for (int oi = 0; oi < order_n; ++oi) {
        int a = oa[static_cast<std::size_t>(oi)], b = ob[static_cast<std::size_t>(oi)];
        while (parent[static_cast<std::size_t>(a)] != a) a = parent[static_cast<std::size_t>(a)];
        while (parent[static_cast<std::size_t>(b)] != b) b = parent[static_cast<std::size_t>(b)];
        if (a == b) continue;
        int root = std::min(a, b), other = std::max(a, b); parent[static_cast<std::size_t>(other)] = root;
        for (int i = 0; i < m; ++i) if (cross[static_cast<std::size_t>(i)] && !enabled[static_cast<std::size_t>(i)]) {
            int x = ba[static_cast<std::size_t>(i)], y = bb[static_cast<std::size_t>(i)];
            while (parent[static_cast<std::size_t>(x)] != x) x = parent[static_cast<std::size_t>(x)];
            while (parent[static_cast<std::size_t>(y)] != y) y = parent[static_cast<std::size_t>(y)];
            if (x == y) {
                const int u = eu[static_cast<std::size_t>(i)], v = ev[static_cast<std::size_t>(i)];
                residual[static_cast<std::size_t>(u * stride + v)] += uv[static_cast<std::size_t>(i)];
                residual[static_cast<std::size_t>(v * stride + u)] += vu[static_cast<std::size_t>(i)];
                enabled[static_cast<std::size_t>(i)] = true;
            }
        }
        for (int u = 0; u < n; ++u) { int x = block[static_cast<std::size_t>(u)]; while (parent[static_cast<std::size_t>(x)] != x) x = parent[static_cast<std::size_t>(x)]; allowed[static_cast<std::size_t>(u)] = x == root; }
        augment(residual, n, allowed);
    }
    std::int64_t flow = 0;
    for (int u = 0; u < n; ++u) flow += source_cap[static_cast<std::size_t>(u)] - residual[static_cast<std::size_t>(n * stride + u)];
    return flow;
}
