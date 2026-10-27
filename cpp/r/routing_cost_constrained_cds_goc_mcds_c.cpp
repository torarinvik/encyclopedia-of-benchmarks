// Clean-room bounded GOC-MCDS-C construction trace.
#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_N = 8;
void put_i64(std::uint8_t* out, std::size_t at, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) { out[at + byte] = static_cast<std::uint8_t>(bits & 255u); bits >>= 8; }
}
}

extern "C" std::int64_t routing_cost_constrained_cds_goc_mcds_c(
        const std::int64_t* input, std::size_t length, std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length < 3 || length > 17 || input[0] < 1 || input[0] > 8) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    if (length != 1 + 2 * n) return -1;
    const auto full = (std::uint64_t{1} << n) - 1;
    std::array<std::uint64_t, MAX_N> adjacency{};
    std::array<std::int64_t, MAX_N> ids{};
    for (std::size_t v = 0; v < n; ++v) {
        const auto mask = input[1 + v]; ids[v] = input[1 + n + v];
        if (mask < 0 || static_cast<std::uint64_t>(mask) > full
                || (static_cast<std::uint64_t>(mask) & (std::uint64_t{1} << v))
                || ids[v] < 1 || ids[v] > 1000) return -1;
        adjacency[v] = static_cast<std::uint64_t>(mask);
        for (std::size_t u = 0; u < v; ++u) if (ids[u] == ids[v]) return -1;
    }
    for (std::size_t u = 0; u < n; ++u)
        for (std::size_t v = 0; v < n; ++v)
            if (((adjacency[u] >> v) & 1u) != ((adjacency[v] >> u) & 1u)) return -1;
    std::uint64_t reached = 1;
    for (;;) {
        auto expanded = reached;
        for (std::size_t v = 0; v < n; ++v) if ((reached >> v) & 1u) expanded |= adjacency[v];
        if (expanded == reached) break;
        reached = expanded;
    }
    if (reached != full) return -1;

    auto white = full;
    std::uint64_t independent = 0;
    while (white != 0) {
        std::uint64_t black = 0;
        for (std::size_t v = 0; v < n; ++v) {
            if (((white >> v) & 1u) == 0) continue;
            bool lower = false;
            for (std::size_t u = 0; u < n; ++u)
                if ((white & (std::uint64_t{1} << u)) && (adjacency[v] & (std::uint64_t{1} << u)) && ids[u] < ids[v]) lower = true;
            if (!lower) black |= std::uint64_t{1} << v;
        }
        if (black == 0) return -1;
        independent |= black;
        auto removed = black;
        for (std::size_t v = 0; v < n; ++v) if ((black >> v) & 1u) removed |= adjacency[v];
        white &= ~removed;
    }

    std::array<std::size_t, MAX_N> order{};
    for (std::size_t i = 0; i < n; ++i) order[i] = i;
    std::sort(order.begin(), order.begin() + static_cast<std::ptrdiff_t>(n),
              [&](std::size_t a, std::size_t b) { return ids[a] < ids[b]; });
    std::uint64_t connectors = 0;
    for (std::size_t a = 0; a < n; ++a) {
        const auto source = order[a]; if (((independent >> source) & 1u) == 0) continue;
        for (std::size_t b = a + 1; b < n; ++b) {
            const auto target = order[b]; if (((independent >> target) & 1u) == 0) continue;
            std::array<int, MAX_N> parent{}; parent.fill(-2);
            std::array<std::size_t, MAX_N> queue{}; std::size_t head = 0, tail = 0;
            parent[source] = -1; queue[tail++] = source;
            while (head < tail && parent[target] == -2) {
                const auto current = queue[head++];
                for (std::size_t oi = 0; oi < n; ++oi) {
                    const auto next = order[oi];
                    if ((adjacency[current] & (std::uint64_t{1} << next)) && parent[next] == -2) {
                        parent[next] = static_cast<int>(current); queue[tail++] = next;
                    }
                }
            }
            if (parent[target] == -2) return -1;
            std::array<std::size_t, MAX_N> path{}; std::size_t path_length = 0, current = target;
            while (current != source) { path[path_length++] = current; current = static_cast<std::size_t>(parent[current]); }
            path[path_length++] = source;
            if (path_length <= 4) for (std::size_t i = 1; i + 1 < path_length; ++i) connectors |= std::uint64_t{1} << path[i];
        }
    }
    if (output == nullptr || capacity < 16) return -2;
    std::array<std::uint8_t, 16> staged{};
    put_i64(staged.data(), 0, static_cast<std::int64_t>(independent));
    put_i64(staged.data(), 8, static_cast<std::int64_t>(independent | connectors));
    std::copy(staged.begin(), staged.end(), output);
    return 16;
}
