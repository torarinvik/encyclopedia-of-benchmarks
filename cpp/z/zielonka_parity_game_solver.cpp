#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int kMaxVertices = 8;
constexpr int kMaxEdges = 20;
constexpr std::size_t kMaxParseableInput = 59;
using Mask = std::uint32_t;

Mask attractor(Mask active, int player, Mask target,
               const std::array<int, kMaxVertices>& owners,
               const std::array<Mask, kMaxVertices>& adjacency, int n) {
    Mask attracted = target;
    for (;;) {
        Mask additions = 0;
        for (int vertex = 0; vertex < n; ++vertex) {
            const Mask bit = Mask{1} << vertex;
            if ((active & bit) == 0 || (attracted & bit) != 0) continue;
            const Mask successors = adjacency[vertex] & active;
            if (owners[vertex] == player) {
                if ((successors & attracted) != 0) additions |= bit;
            } else if (successors != 0 && (successors & ~attracted) == 0) {
                additions |= bit;
            }
        }
        if (additions == 0) return attracted;
        attracted |= additions;
    }
}

Mask solve(Mask active, const std::array<int, kMaxVertices>& owners,
           const std::array<int, kMaxVertices>& priorities,
           const std::array<Mask, kMaxVertices>& adjacency, int n) {
    if (active == 0) return 0;
    int lowest = 6;
    for (int vertex = 0; vertex < n; ++vertex)
        if ((active & (Mask{1} << vertex)) != 0 && priorities[vertex] < lowest)
            lowest = priorities[vertex];
    const int player = lowest & 1;
    Mask target = 0;
    for (int vertex = 0; vertex < n; ++vertex)
        if ((active & (Mask{1} << vertex)) != 0 && priorities[vertex] == lowest)
            target |= Mask{1} << vertex;

    const Mask first = attractor(active, player, target, owners, adjacency, n);
    const Mask remainder = active & ~first;
    const Mask evenFirst = solve(remainder, owners, priorities, adjacency, n);
    const Mask oddFirst = remainder & ~evenFirst;
    const Mask opponentRegion = player == 1 ? evenFirst : oddFirst;
    if (opponentRegion == 0) return evenFirst | (player == 0 ? first : 0);

    const Mask second = attractor(active, 1 - player, opponentRegion, owners, adjacency, n);
    const Mask evenSecond = solve(active & ~second, owners, priorities, adjacency, n);
    return evenSecond | (player == 1 ? second : 0);
}
}

extern "C" std::int64_t zielonka_parity_game_solver(const std::int64_t* input,
                                                       std::size_t length) {
    if (input == nullptr || length < 6 || length > kMaxParseableInput) return -1;
    const std::int64_t vertexRaw = input[0], edgeRaw = input[1];
    if (vertexRaw < 1 || vertexRaw > kMaxVertices || edgeRaw < vertexRaw || edgeRaw > kMaxEdges)
        return -1;
    const int n = static_cast<int>(vertexRaw), edgeCount = static_cast<int>(edgeRaw);
    if (length != static_cast<std::size_t>(2 + 2 * n + 2 * edgeCount)) return -1;

    std::array<int, kMaxVertices> owners{};
    std::array<int, kMaxVertices> priorities{};
    std::array<Mask, kMaxVertices> adjacency{};
    std::array<int, kMaxVertices> outdegree{};
    std::size_t cursor = 2;
    for (int vertex = 0; vertex < n; ++vertex) {
        const std::int64_t owner = input[cursor++], priority = input[cursor++];
        if (owner < 0 || owner > 1 || priority < 0 || priority > 5) return -1;
        owners[vertex] = static_cast<int>(owner);
        priorities[vertex] = static_cast<int>(priority);
    }
    for (int edge = 0; edge < edgeCount; ++edge) {
        const std::int64_t sourceRaw = input[cursor++], destinationRaw = input[cursor++];
        if (sourceRaw < 0 || sourceRaw >= n || destinationRaw < 0 || destinationRaw >= n) return -1;
        const int source = static_cast<int>(sourceRaw), destination = static_cast<int>(destinationRaw);
        const Mask bit = Mask{1} << destination;
        if ((adjacency[source] & bit) != 0) return -1;
        adjacency[source] |= bit;
        ++outdegree[source];
    }
    for (int vertex = 0; vertex < n; ++vertex)
        if (outdegree[vertex] == 0) return -1;
    return static_cast<std::int64_t>(solve((Mask{1} << n) - 1, owners, priorities, adjacency, n));
}
