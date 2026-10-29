#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MaxVertices = 6;
constexpr std::size_t MaxEdges = 12;
constexpr std::size_t MaxK = 8;
constexpr std::size_t MaxInputLength = 41;
constexpr std::size_t MaxFrontier = 1 + MaxK * MaxEdges;

void write_i64(std::uint8_t* output, std::size_t offset, std::int64_t value) noexcept {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
} // namespace

extern "C" std::int64_t k_shortest_walk(
    const std::int64_t* values, std::size_t length,
    std::uint8_t* output, std::size_t output_capacity) noexcept {
    if (values == nullptr || length < 5 || length > MaxInputLength) return -1;
    const auto n_value = values[0];
    const auto m_value = values[1];
    const auto source_value = values[2];
    const auto target_value = values[3];
    const auto k_value = values[4];
    if (n_value < 1 || n_value > static_cast<std::int64_t>(MaxVertices) ||
        m_value < 0 || m_value > static_cast<std::int64_t>(MaxEdges) ||
        k_value < 1 || k_value > static_cast<std::int64_t>(MaxK) ||
        source_value < 0 || source_value >= n_value || target_value < 0 || target_value >= n_value)
        return -1;
    const auto n = static_cast<std::size_t>(n_value);
    const auto m = static_cast<std::size_t>(m_value);
    const auto source = static_cast<std::size_t>(source_value);
    const auto target = static_cast<std::size_t>(target_value);
    const auto k = static_cast<std::size_t>(k_value);
    if (length != 5 + 3 * m) return -1;

    std::int64_t head[MaxVertices], edge_to[MaxEdges], edge_weight[MaxEdges], edge_next[MaxEdges];
    for (std::size_t vertex = 0; vertex < n; ++vertex) head[vertex] = -1;
    for (std::size_t edge = 0; edge < m; ++edge) {
        const auto u = values[5 + 3 * edge];
        const auto v = values[6 + 3 * edge];
        const auto weight = values[7 + 3 * edge];
        if (u < 0 || u >= n_value || v < 0 || v >= n_value || weight < 0 || weight > 1000) return -1;
        edge_to[edge] = v;
        edge_weight[edge] = weight;
        edge_next[edge] = head[static_cast<std::size_t>(u)];
        head[static_cast<std::size_t>(u)] = static_cast<std::int64_t>(edge);
    }
    if (output == nullptr || output_capacity < 8 * k) return -2;

    std::int64_t queue_distance[MaxFrontier], queue_vertex[MaxFrontier], queue_order[MaxFrontier];
    std::int64_t expanded[MaxVertices]{}, answers[MaxK];
    std::size_t queue_count = 1, answer_count = 0;
    std::int64_t next_order = 1;
    queue_distance[0] = 0;
    queue_vertex[0] = static_cast<std::int64_t>(source);
    queue_order[0] = 0;

    while (queue_count != 0 && answer_count < k) {
        const auto distance = queue_distance[0];
        const auto vertex = static_cast<std::size_t>(queue_vertex[0]);
        for (std::size_t slot = 1; slot < queue_count; ++slot) {
            queue_distance[slot - 1] = queue_distance[slot];
            queue_vertex[slot - 1] = queue_vertex[slot];
            queue_order[slot - 1] = queue_order[slot];
        }
        --queue_count;
        if (expanded[vertex] >= static_cast<std::int64_t>(k)) continue;
        ++expanded[vertex];
        if (vertex == target) {
            answers[answer_count++] = distance;
            if (answer_count == k) break;
        }
        for (auto edge = head[vertex]; edge >= 0; edge = edge_next[static_cast<std::size_t>(edge)]) {
            const auto edge_index = static_cast<std::size_t>(edge);
            const auto candidate_distance = distance + edge_weight[edge_index];
            const auto candidate_vertex = edge_to[edge_index];
            const auto candidate_order = next_order++;
            auto position = queue_count;
            while (position > 0 &&
                   (queue_distance[position - 1] > candidate_distance ||
                    (queue_distance[position - 1] == candidate_distance &&
                     queue_order[position - 1] > candidate_order))) {
                queue_distance[position] = queue_distance[position - 1];
                queue_vertex[position] = queue_vertex[position - 1];
                queue_order[position] = queue_order[position - 1];
                --position;
            }
            queue_distance[position] = candidate_distance;
            queue_vertex[position] = candidate_vertex;
            queue_order[position] = candidate_order;
            ++queue_count;
        }
    }
    while (answer_count < k) answers[answer_count++] = -1;
    for (std::size_t index = 0; index < k; ++index)
        write_i64(output, 8 * index, answers[index]);
    return static_cast<std::int64_t>(8 * k);
}
