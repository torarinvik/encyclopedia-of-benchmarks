#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MaxVertices = 8;
constexpr std::size_t MaxEdges = 32;
constexpr std::size_t MaxInputLength = 2 + 2 * MaxEdges;
}

extern "C" std::int64_t incremental_scc(const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length < 2 || length > MaxInputLength || input[0] < 1 ||
        input[0] > static_cast<std::int64_t>(MaxVertices) || input[1] < 0 ||
        input[1] > static_cast<std::int64_t>(MaxEdges)) return -1;
    const auto vertex_count = static_cast<std::size_t>(input[0]);
    const auto edge_count = static_cast<std::size_t>(input[1]);
    if (length != 2 + 2 * edge_count) return -1;

    std::size_t sources[MaxEdges], destinations[MaxEdges];
    for (std::size_t edge = 0; edge < edge_count; ++edge) {
        const auto source = input[2 + 2 * edge], destination = input[3 + 2 * edge];
        if (source < 0 || destination < 0 || source >= static_cast<std::int64_t>(vertex_count) ||
            destination >= static_cast<std::int64_t>(vertex_count)) return -1;
        sources[edge] = static_cast<std::size_t>(source);
        destinations[edge] = static_cast<std::size_t>(destination);
    }

    bool reachable[MaxVertices][MaxVertices]{};
    for (std::size_t vertex = 0; vertex < vertex_count; ++vertex) reachable[vertex][vertex] = true;
    std::int64_t checksum = 0;
    for (std::size_t edge = 0; edge < edge_count; ++edge) {
        bool predecessors[MaxVertices], successors[MaxVertices];
        const auto source = sources[edge], destination = destinations[edge];
        for (std::size_t vertex = 0; vertex < vertex_count; ++vertex) {
            predecessors[vertex] = reachable[vertex][source];
            successors[vertex] = reachable[destination][vertex];
        }
        for (std::size_t first = 0; first < vertex_count; ++first)
            for (std::size_t second = 0; second < vertex_count; ++second)
                if (predecessors[first] && successors[second]) reachable[first][second] = true;

        bool assigned[MaxVertices]{};
        std::size_t components = 0;
        for (std::size_t first = 0; first < vertex_count; ++first) {
            if (assigned[first]) continue;
            ++components;
            for (std::size_t vertex = first; vertex < vertex_count; ++vertex)
                if (reachable[first][vertex] && reachable[vertex][first]) assigned[vertex] = true;
        }
        checksum += static_cast<std::int64_t>(edge + 1) * static_cast<std::int64_t>(components);
    }
    return checksum;
}
