#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxVertices = 8;
constexpr std::size_t kMaxEdges = 28;
constexpr std::size_t kMaxInput = 2 + kMaxVertices + 2 * kMaxEdges;
constexpr std::size_t kMaxFields = 1 + kMaxVertices * (1 + kMaxVertices);

void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value)
{
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 255U);
        bits >>= 8;
    }
}

bool unique_shortest_paths(const std::uint8_t *adjacency, std::size_t n)
{
    for (std::size_t source = 0; source < n; ++source) {
        int distance[kMaxVertices];
        std::uint8_t ways[kMaxVertices]{};
        std::size_t queue[kMaxVertices]{};
        for (std::size_t i = 0; i < n; ++i) distance[i] = -1;
        std::size_t head = 0, tail = 0;
        distance[source] = 0; ways[source] = 1; queue[tail++] = source;
        while (head < tail) {
            const auto vertex = queue[head++];
            for (std::size_t neighbor = 0; neighbor < n; ++neighbor) {
                if (adjacency[vertex * kMaxVertices + neighbor] == 0) continue;
                if (distance[neighbor] < 0) {
                    distance[neighbor] = distance[vertex] + 1;
                    ways[neighbor] = ways[vertex];
                    queue[tail++] = neighbor;
                } else if (distance[neighbor] == distance[vertex] + 1) {
                    const auto sum = static_cast<unsigned>(ways[neighbor]) + ways[vertex];
                    ways[neighbor] = static_cast<std::uint8_t>(sum > 1U ? 2U : sum);
                }
            }
        }
        for (std::size_t vertex = 0; vertex < n; ++vertex) if (ways[vertex] != 1) return false;
    }
    return true;
}
} // namespace

extern "C" std::int64_t hub_labeling_pruned(const std::int64_t *input, std::size_t length,
                                              std::uint8_t *output, std::size_t capacity) noexcept
{
    if (input == nullptr || length < 3 || length > kMaxInput) return -1;
    const auto n_value = input[0], m_value = input[1];
    if (n_value < 1 || n_value > static_cast<std::int64_t>(kMaxVertices)
        || m_value < 0 || m_value > static_cast<std::int64_t>(kMaxEdges)) return -1;
    const auto n = static_cast<std::size_t>(n_value), m = static_cast<std::size_t>(m_value);
    if (length != 2 + n + 2 * m) return -1;
    bool seen_order[kMaxVertices]{};
    for (std::size_t i = 0; i < n; ++i) {
        const auto vertex = input[2 + i];
        if (vertex < 0 || static_cast<std::uint64_t>(vertex) >= n || seen_order[static_cast<std::size_t>(vertex)]) return -1;
        seen_order[static_cast<std::size_t>(vertex)] = true;
    }
    std::uint8_t adjacency[kMaxVertices * kMaxVertices]{};
    std::int64_t previous_left = -1, previous_right = -1;
    for (std::size_t edge = 0; edge < m; ++edge) {
        const auto left = input[2 + n + 2 * edge], right = input[3 + n + 2 * edge];
        if (left < 0 || right <= left || static_cast<std::uint64_t>(right) >= n
            || left < previous_left || (left == previous_left && right <= previous_right)) return -1;
        previous_left = left; previous_right = right;
        adjacency[static_cast<std::size_t>(left) * kMaxVertices + static_cast<std::size_t>(right)] = 1;
        adjacency[static_cast<std::size_t>(right) * kMaxVertices + static_cast<std::size_t>(left)] = 1;
    }
    if (!unique_shortest_paths(adjacency, n)) return -1;

    std::int16_t labels[kMaxVertices * kMaxVertices];
    for (auto &value : labels) value = -1;
    for (std::size_t order_index = 0; order_index < n; ++order_index) {
        const auto hub = static_cast<std::size_t>(input[2 + order_index]);
        int distance[kMaxVertices];
        std::size_t queue[kMaxVertices]{};
        for (std::size_t i = 0; i < n; ++i) distance[i] = -1;
        std::size_t head = 0, tail = 0;
        distance[hub] = 0; queue[tail++] = hub;
        while (head < tail) {
            const auto vertex = queue[head++];
            int estimate = 2 * static_cast<int>(kMaxVertices);
            for (std::size_t common = 0; common < n; ++common) {
                const auto from_hub = labels[hub * kMaxVertices + common];
                const auto from_vertex = labels[vertex * kMaxVertices + common];
                if (from_hub >= 0 && from_vertex >= 0 && from_hub + from_vertex < estimate)
                    estimate = from_hub + from_vertex;
            }
            if (estimate <= distance[vertex]) continue;
            labels[vertex * kMaxVertices + hub] = static_cast<std::int16_t>(distance[vertex]);
            for (std::size_t neighbor = 0; neighbor < n; ++neighbor) {
                if (adjacency[vertex * kMaxVertices + neighbor] != 0 && distance[neighbor] < 0) {
                    distance[neighbor] = distance[vertex] + 1;
                    queue[tail++] = neighbor;
                }
            }
        }
    }
    std::int64_t fields[kMaxFields]{};
    std::size_t field_count = 0;
    fields[field_count++] = static_cast<std::int64_t>(n);
    for (std::size_t vertex = 0; vertex < n; ++vertex) {
        const auto count_index = field_count++;
        std::int64_t count = 0;
        for (std::size_t hub = 0; hub < n; ++hub) {
            const auto value = labels[vertex * kMaxVertices + hub];
            if (value >= 0) {
                fields[field_count++] = static_cast<std::int64_t>(hub) | (static_cast<std::int64_t>(value) << 8);
                ++count;
            }
        }
        fields[count_index] = count;
    }
    const auto bytes = field_count * 8;
    if (output == nullptr || capacity < bytes) return -2;
    std::uint8_t staged[8 * kMaxFields]{};
    for (std::size_t i = 0; i < field_count; ++i) store_i64_le(staged, 8 * i, fields[i]);
    for (std::size_t i = 0; i < bytes; ++i) output[i] = staged[i];
    return static_cast<std::int64_t>(bytes);
}
