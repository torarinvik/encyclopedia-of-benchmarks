/* 0-1 BFS over a bounded directed graph encoded as weighted edge triples. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxVertices = 64;
constexpr std::size_t kMaxEdges = 1024;
constexpr std::size_t kDequeCapacity = 4097;
}

extern "C" std::int64_t zero_one_bfs(const std::int64_t *values, std::size_t length,
                                      std::uint8_t *output, std::size_t output_capacity) noexcept
{
    if (values == nullptr || length < 3 || length > 3 + 3 * kMaxEdges) return -1;
    if (values[0] < 1 || values[0] > static_cast<std::int64_t>(kMaxVertices) ||
        values[2] < 0 || values[2] > static_cast<std::int64_t>(kMaxEdges)) return -1;
    const auto vertices = static_cast<std::size_t>(values[0]);
    const auto source = static_cast<std::size_t>(values[1]);
    const auto edge_count = static_cast<std::size_t>(values[2]);
    if (source >= vertices || length != 3 + 3 * edge_count) return -1;

    std::uint64_t zero_edges[kMaxVertices]{};
    std::uint64_t one_edges[kMaxVertices]{};
    std::uint8_t distance[kMaxVertices];
    std::uint8_t deque[kDequeCapacity];
    for (std::size_t vertex = 0; vertex < vertices; ++vertex) distance[vertex] = UINT8_MAX;
    for (std::size_t edge = 0; edge < edge_count; ++edge) {
        const auto origin_value = values[3 + 3 * edge];
        const auto destination_value = values[4 + 3 * edge];
        const auto weight = values[5 + 3 * edge];
        if (origin_value < 0 || destination_value < 0 ||
            static_cast<std::uint64_t>(origin_value) >= vertices ||
            static_cast<std::uint64_t>(destination_value) >= vertices ||
            (weight != 0 && weight != 1)) return -1;
        const auto origin = static_cast<std::size_t>(origin_value);
        const auto destination = static_cast<std::size_t>(destination_value);
        const auto mask = UINT64_C(1) << destination;
        if (weight == 0) zero_edges[origin] |= mask;
        else one_edges[origin] |= mask;
    }
    if (output_capacity < vertices || output == nullptr) return -2;

    std::size_t head = 0, tail = 1, queued = 1;
    deque[0] = static_cast<std::uint8_t>(source);
    distance[source] = 0;
    while (queued != 0) {
        const auto origin = static_cast<std::size_t>(deque[head]);
        head = (head + 1) % kDequeCapacity;
        --queued;
        const auto base = distance[origin];
        for (std::size_t destination = 0; destination < vertices; ++destination) {
            const auto mask = UINT64_C(1) << destination;
            if ((zero_edges[origin] & mask) != 0 && base < distance[destination]) {
                distance[destination] = base;
                head = head == 0 ? kDequeCapacity - 1 : head - 1;
                deque[head] = static_cast<std::uint8_t>(destination);
                ++queued;
            }
            const auto candidate = static_cast<std::uint8_t>(base + 1);
            if ((one_edges[origin] & mask) != 0 && candidate < distance[destination]) {
                distance[destination] = candidate;
                deque[tail] = static_cast<std::uint8_t>(destination);
                tail = (tail + 1) % kDequeCapacity;
                ++queued;
            }
        }
    }

    for (std::size_t vertex = 0; vertex < vertices; ++vertex) output[vertex] = distance[vertex];
    return static_cast<std::int64_t>(vertices);
}
