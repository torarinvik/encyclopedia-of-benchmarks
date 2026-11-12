#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxVertices = 16;
constexpr std::size_t kMaxEdges = 64;
constexpr std::size_t kMaxInput = 133;
constexpr std::size_t kMaxPaths = 162;
constexpr std::size_t kMaxOutput = 1296;

struct Search {
    std::size_t n;
    std::size_t target;
    const std::array<bool, kMaxVertices * kMaxVertices>& predecessor;
    const std::array<bool, kMaxVertices>& useful;
    std::array<std::size_t, kMaxVertices>& path;
    std::array<std::uint8_t, kMaxOutput>& staged;
    std::size_t used = 0;
    std::size_t count = 0;
    bool overflow = false;

    void visit(std::size_t u, std::size_t depth)
    {
        if (overflow) return;
        path[depth] = u;
        if (u == target) {
            if (count >= kMaxPaths || used + depth + 2 > kMaxOutput) { overflow = true; return; }
            for (std::size_t i = 0; i <= depth; ++i) staged[used++] = static_cast<std::uint8_t>(path[i]);
            staged[used++] = 0xff;
            ++count;
            return;
        }
        for (std::size_t v = 0; v < n && !overflow; ++v) {
            if (useful[v] && predecessor[v * kMaxVertices + u]) visit(v, depth + 1);
        }
    }
};
}

extern "C" std::int64_t all_shortest_paths_unweighted(const std::int64_t* input, std::size_t length,
                                                      std::uint8_t* output, std::size_t capacity)
{
    if (input == nullptr || length < 4 || length > kMaxInput) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(kMaxVertices)
        || input[1] < 0 || input[1] > static_cast<std::int64_t>(kMaxEdges)) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    const auto m = static_cast<std::size_t>(input[1]);
    if (input[2] < 0 || input[2] >= static_cast<std::int64_t>(n)
        || input[3] < 0 || input[3] >= static_cast<std::int64_t>(n) || length != 4 + 2 * m) return -1;
    const auto source = static_cast<std::size_t>(input[2]);
    const auto target = static_cast<std::size_t>(input[3]);

    std::array<bool, kMaxVertices * kMaxVertices> adjacent{};
    for (std::size_t e = 0; e < m; ++e) {
        const auto raw_u = input[4 + 2 * e], raw_v = input[5 + 2 * e];
        if (raw_u < 0 || raw_u >= static_cast<std::int64_t>(n)
            || raw_v < 0 || raw_v >= static_cast<std::int64_t>(n) || raw_u == raw_v) return -1;
        const auto u = static_cast<std::size_t>(raw_u), v = static_cast<std::size_t>(raw_v);
        if (adjacent[u * kMaxVertices + v]) return -1;
        adjacent[u * kMaxVertices + v] = adjacent[v * kMaxVertices + u] = true;
    }

    std::array<std::int64_t, kMaxVertices> distance;
    distance.fill(-1);
    std::array<std::size_t, kMaxVertices> queue{};
    std::array<bool, kMaxVertices * kMaxVertices> predecessor{};
    std::size_t head = 0, tail = 0;
    distance[source] = 0;
    queue[tail++] = source;
    while (head < tail) {
        const auto u = queue[head++];
        for (std::size_t v = 0; v < n; ++v) {
            if (!adjacent[u * kMaxVertices + v]) continue;
            if (distance[v] < 0) { distance[v] = distance[u] + 1; queue[tail++] = v; }
            if (distance[v] == distance[u] + 1) predecessor[v * kMaxVertices + u] = true;
        }
    }

    std::array<bool, kMaxVertices> useful{};
    if (distance[target] >= 0) {
        std::array<std::size_t, kMaxVertices> stack{};
        std::size_t size = 0;
        useful[target] = true;
        stack[size++] = target;
        while (size > 0) {
            const auto v = stack[--size];
            for (std::size_t u = 0; u < n; ++u) {
                if (predecessor[v * kMaxVertices + u] && !useful[u]) {
                    useful[u] = true;
                    stack[size++] = u;
                }
            }
        }
    }

    std::array<std::size_t, kMaxVertices> path{};
    std::array<std::uint8_t, kMaxOutput> staged{};
    Search search{n, target, predecessor, useful, path, staged};
    if (distance[target] >= 0) search.visit(source, 0);
    if (search.overflow) return -2;
    if (output == nullptr || capacity < search.used) return -2;
    for (std::size_t i = 0; i < search.used; ++i) output[i] = staged[i];
    return static_cast<std::int64_t>(search.count);
}
