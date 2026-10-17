#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxVertices = 32;
constexpr std::size_t kMaxEdges = 128;
constexpr std::size_t kMaxInputLength = 2 + 2 * kMaxEdges;
constexpr std::size_t kEdgeTableSize = kMaxVertices * kMaxVertices;
}

extern "C" std::int64_t kahns_algorithm_long(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length < 2 || length > kMaxInputLength) return -1;
    const std::int64_t vertexCount = values[0], edgeCount = values[1];
    if (vertexCount < 1 || vertexCount > static_cast<std::int64_t>(kMaxVertices) || edgeCount < 0 ||
        edgeCount > static_cast<std::int64_t>(kMaxEdges) ||
        length != static_cast<std::size_t>(2 + 2 * edgeCount)) return -1;

    std::int64_t edgeMultiplicity[kEdgeTableSize]{};
    std::int64_t indegree[kMaxVertices]{};
    std::int64_t distance[kMaxVertices]{};
    std::int64_t queue[kMaxVertices]{};
    for (std::int64_t vertex = 0; vertex < vertexCount; ++vertex) distance[vertex] = 1;
    for (std::int64_t edge = 0; edge < edgeCount; ++edge) {
        const std::int64_t source = values[2 + 2 * edge], destination = values[3 + 2 * edge];
        if (source < 0 || source >= vertexCount || destination < 0 || destination >= vertexCount) return -1;
        ++edgeMultiplicity[source * static_cast<std::int64_t>(kMaxVertices) + destination];
        ++indegree[destination];
    }

    std::size_t head = 0, tail = 0;
    for (std::int64_t vertex = 0; vertex < vertexCount; ++vertex)
        if (indegree[vertex] == 0) queue[tail++] = vertex;
    std::int64_t processed = 0, maximum = 1;
    while (head < tail) {
        const std::int64_t source = queue[head++];
        ++processed;
        if (distance[source] > maximum) maximum = distance[source];
        for (std::int64_t destination = 0; destination < vertexCount; ++destination) {
            const std::int64_t copies = edgeMultiplicity[source * static_cast<std::int64_t>(kMaxVertices) + destination];
            if (copies == 0) continue;
            const std::int64_t candidate = distance[source] + 1;
            if (candidate > distance[destination]) distance[destination] = candidate;
            for (std::int64_t copy = 0; copy < copies; ++copy)
                if (--indegree[destination] == 0) queue[tail++] = destination;
        }
    }
    if (processed != vertexCount) return -1;
    for (std::int64_t vertex = 0; vertex < vertexCount; ++vertex)
        if (distance[vertex] > maximum) maximum = distance[vertex];
    return maximum;
}
