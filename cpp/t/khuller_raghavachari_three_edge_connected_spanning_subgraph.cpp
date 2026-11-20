#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t N = 8, M = 28, INPUT = 59;
void put(std::uint8_t* out, std::size_t at, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        out[at + byte] = static_cast<std::uint8_t>(bits & 255U);
        bits >>= 8;
    }
}
}

extern "C" std::int64_t khuller_raghavachari_three_edge_connected_spanning_subgraph(
        const std::int64_t* input, std::size_t length, std::uint8_t* output,
        std::size_t capacity) noexcept {
    if (input == nullptr || length < 2 || length > INPUT) return -1;
    const auto n64 = input[0], m64 = input[1];
    if (n64 < 4 || n64 > 8 || m64 < 6 || m64 > 28
            || length != 2 + 2 * static_cast<std::size_t>(m64)) return -1;
    const auto n = static_cast<std::size_t>(n64), m = static_cast<std::size_t>(m64);
    std::array<std::size_t, M> u{}, v{};
    for (std::size_t e = 0; e < m; ++e) {
        const auto a = input[2 + 2 * e], b = input[3 + 2 * e];
        if (a < 0 || a >= b || b >= n64) return -1;
        u[e] = static_cast<std::size_t>(a); v[e] = static_cast<std::size_t>(b);
        for (std::size_t prior = 0; prior < e; ++prior)
            if (u[prior] == u[e] && v[prior] == v[e]) return -1;
    }
    const auto full = (std::size_t{1} << n) - 1;
    for (std::size_t side = 1; side < full; ++side) {
        if ((side & 1U) == 0) continue;
        std::size_t cut = 0;
        for (std::size_t e = 0; e < m; ++e)
            if (((side >> u[e]) & 1U) != ((side >> v[e]) & 1U)) ++cut;
        if (cut < 3) return -1;
    }

    std::array<bool, M> selected{};
    std::array<std::size_t, N> state{}, discovery{}, finish{}, parent{}, parent_edge{};
    std::array<std::size_t, N> postorder{}, stack_vertex{}, stack_slot{};
    std::size_t post_count = 0, clock = 1, top = 1;
    state[0] = 1; discovery[0] = 0; parent[0] = n; parent_edge[0] = m;
    stack_vertex[0] = 0;
    while (top > 0) {
        const auto frame = top - 1, x = stack_vertex[frame];
        if (stack_slot[frame] < m) {
            const auto e = stack_slot[frame]++;
            std::size_t y = N;
            if (u[e] == x) y = v[e]; else if (v[e] == x) y = u[e];
            if (y == N || state[y] != 0) continue;
            selected[e] = true; state[y] = 1; parent[y] = x; parent_edge[y] = e;
            discovery[y] = clock++;
            stack_vertex[top] = y; stack_slot[top] = 0; ++top;
            continue;
        }
        state[x] = 2;
        finish[x] = clock;
        if (parent_edge[x] < m) postorder[post_count++] = parent_edge[x];
        --top;
    }

    for (std::size_t p = 0; p < post_count; ++p) {
        const auto tree_edge = postorder[p];
        const auto child = parent_edge[u[tree_edge]] == tree_edge ? u[tree_edge] : v[tree_edge];
        const auto upper = parent[child];
        bool has_one_edge_cut = false;
        for (std::size_t removed = 0; removed < m && !has_one_edge_cut; ++removed) {
            if (!selected[removed]) continue;
            std::array<bool, N> seen{};
            std::array<std::size_t, N> queue{};
            std::size_t head = 0, tail = 1;
            seen[upper] = true; queue[0] = upper;
            while (head < tail) {
                const auto current = queue[head++];
                for (std::size_t e = 0; e < m; ++e) {
                    if (!selected[e] || e == removed) continue;
                    const auto next = u[e] == current ? v[e] : v[e] == current ? u[e] : N;
                    if (next < n && !seen[next]) { seen[next] = true; queue[tail++] = next; }
                }
            }
            has_one_edge_cut = !seen[child];
        }
        if (!has_one_edge_cut) continue;
        std::size_t candidate = m, earliest = n;
        for (std::size_t e = 0; e < m; ++e) {
            if (selected[e]) continue;
            const bool u_inside = discovery[child] <= discovery[u[e]] && discovery[u[e]] < finish[child];
            const bool v_inside = discovery[child] <= discovery[v[e]] && discovery[v[e]] < finish[child];
            if (u_inside == v_inside) continue;
            const auto ancestor = u_inside ? v[e] : u[e];
            if (discovery[ancestor] < earliest) { earliest = discovery[ancestor]; candidate = e; }
        }
        if (candidate == m) return -1;
        selected[candidate] = true;
    }

    std::array<std::size_t, N> leader{};
    for (std::size_t vertex = 0; vertex < n; ++vertex) leader[vertex] = vertex;
    for (std::size_t e = 0; e < m; ++e) {
        if (selected[e]) continue;
        auto a = u[e], b = v[e];
        while (leader[a] != a) { leader[a] = leader[leader[a]]; a = leader[a]; }
        while (leader[b] != b) { leader[b] = leader[leader[b]]; b = leader[b]; }
        if (a != b) { leader[b] = a; selected[e] = true; }
    }
    std::size_t count = 0;
    for (std::size_t e = 0; e < m; ++e) if (selected[e]) ++count;
    const auto bytes = 8 * (1 + 2 * count);
    if (output == nullptr || capacity < bytes) return -2;
    put(output, 0, static_cast<std::int64_t>(count));
    std::size_t slot = 0;
    for (std::size_t e = 0; e < m; ++e) if (selected[e]) {
        put(output, 8 * (1 + 2 * slot), static_cast<std::int64_t>(u[e]));
        put(output, 8 * (2 + 2 * slot), static_cast<std::int64_t>(v[e]));
        ++slot;
    }
    return static_cast<std::int64_t>(bytes);
}
