#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_vertices = 16;
constexpr std::size_t max_edges = 64;
constexpr std::size_t max_input_length = 3 + 3 * max_edges;

void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
}
} // namespace

extern "C" std::int64_t d_esopo_pape(const std::int64_t *values, std::size_t length,
                                     std::uint8_t *output, std::size_t capacity) {
    if (values == nullptr || length < 3 || length > max_input_length) return -1;
    const auto raw_n = values[0], raw_m = values[1], raw_source = values[2];
    if (raw_n < 1 || raw_n > static_cast<std::int64_t>(max_vertices) ||
        raw_m < 0 || raw_m > static_cast<std::int64_t>(max_edges) ||
        raw_source < 0 || raw_source >= raw_n ||
        length != 3 + 3 * static_cast<std::size_t>(raw_m)) return -1;

    const auto n = static_cast<std::size_t>(raw_n);
    const auto m = static_cast<std::size_t>(raw_m);
    std::array<int, max_vertices> head;
    head.fill(-1);
    std::array<int, max_edges> to{}, next{};
    std::array<std::int64_t, max_edges> weight{};
    for (std::size_t edge = 0; edge < m; ++edge) {
        const auto u = values[3 + 3 * edge], v = values[4 + 3 * edge], w = values[5 + 3 * edge];
        if (u < 0 || u >= raw_n || v < 0 || v >= raw_n || w < 0 || w > 1000) return -1;
        to[edge] = static_cast<int>(v);
        weight[edge] = w;
        next[edge] = head[static_cast<std::size_t>(u)];
        head[static_cast<std::size_t>(u)] = static_cast<int>(edge);
    }

    std::array<std::int64_t, max_vertices> distance{};
    std::array<bool, max_vertices> reachable{}, queued{}, removed_before{};
    std::array<int, max_vertices> deque{};
    std::size_t front = 0, size = 1;
    const auto source = static_cast<std::size_t>(raw_source);
    deque[0] = static_cast<int>(source);
    distance[source] = 0;
    reachable[source] = queued[source] = true;
    while (size != 0) {
        const int vertex = deque[front];
        front = (front + 1) % n;
        --size;
        queued[static_cast<std::size_t>(vertex)] = false;
        removed_before[static_cast<std::size_t>(vertex)] = true;
        for (int edge = head[static_cast<std::size_t>(vertex)]; edge != -1; edge = next[edge]) {
            const int neighbor = to[edge];
            const auto vi = static_cast<std::size_t>(vertex), ni = static_cast<std::size_t>(neighbor);
            const auto candidate = distance[vi] + weight[static_cast<std::size_t>(edge)];
            if (!reachable[ni] || candidate < distance[ni]) {
                distance[ni] = candidate;
                reachable[ni] = true;
                if (!queued[ni]) {
                    if (removed_before[ni]) {
                        front = (front + n - 1) % n;
                        deque[front] = neighbor;
                    } else {
                        deque[(front + size) % n] = neighbor;
                    }
                    ++size;
                    queued[ni] = true;
                }
            }
        }
    }

    const auto byte_count = 8 * n;
    if (output == nullptr || capacity < byte_count) return -2;
    for (std::size_t vertex = 0; vertex < n; ++vertex)
        store_i64_le(output, 8 * vertex, reachable[vertex] ? distance[vertex] : -1);
    return static_cast<std::int64_t>(byte_count);
}
