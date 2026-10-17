/* DFS that visits a successor only after all of its predecessors are visited. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_nodes = 16;
constexpr std::size_t max_input_values = 2 + max_nodes * max_nodes;
constexpr std::size_t max_events = max_nodes + max_nodes * (max_nodes - 1) / 2;

struct Event { std::int32_t type, node, order; };

bool visit_node(std::size_t node, std::size_t count,
                const bool adjacent[max_nodes][max_nodes],
                const bool predecessors[max_nodes][max_nodes], bool visited[max_nodes],
                Event events[max_events], std::size_t &event_count, std::int32_t &next_order)
{
    if (event_count >= max_events) return false;
    visited[node] = true;
    events[event_count++] = {1, static_cast<std::int32_t>(node), next_order++};
    for (std::size_t child = 0; child < count; ++child) {
        if (!adjacent[node][child] || visited[child]) continue;
        bool all_visited = true;
        for (std::size_t parent = 0; parent < count; ++parent)
            if (predecessors[child][parent] && !visited[parent]) { all_visited = false; break; }
        if (all_visited) {
            if (!visit_node(child, count, adjacent, predecessors, visited, events, event_count, next_order)) return false;
        } else {
            if (event_count >= max_events) return false;
            events[event_count++] = {0, static_cast<std::int32_t>(child), -1};
        }
    }
    return true;
}

void write_i32_le(std::uint8_t *output, std::size_t offset, std::int32_t value) noexcept
{
    const auto bits = static_cast<std::uint32_t>(value);
    for (std::size_t byte = 0; byte < 4; ++byte) output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t predecessor_constrained_dfs(const std::int64_t *input, std::size_t length,
                                                       std::uint8_t *output, std::size_t output_capacity)
{
    if (input == nullptr || length < 2 || length > max_input_values) return -1;
    const auto raw_count = input[0], raw_start = input[1];
    if (raw_count < 1 || raw_count > static_cast<std::int64_t>(max_nodes) || raw_start < 0 || raw_start >= raw_count ||
        length != 2 + static_cast<std::size_t>(raw_count) * static_cast<std::size_t>(raw_count)) return -1;
    const auto count = static_cast<std::size_t>(raw_count);
    bool adjacent[max_nodes][max_nodes]{}, predecessors[max_nodes][max_nodes]{};
    std::size_t indegree[max_nodes]{}, queue[max_nodes]{};
    for (std::size_t from = 0; from < count; ++from) {
        for (std::size_t to = 0; to < count; ++to) {
            const auto bit = input[2 + from * count + to];
            if ((bit != 0 && bit != 1) || (from == to && bit != 0)) return -1;
            if (bit != 0) { adjacent[from][to] = true; predecessors[to][from] = true; ++indegree[to]; }
        }
    }
    std::size_t head = 0, tail = 0;
    for (std::size_t node = 0; node < count; ++node) if (indegree[node] == 0) queue[tail++] = node;
    while (head < tail) {
        const auto node = queue[head++];
        for (std::size_t child = 0; child < count; ++child)
            if (adjacent[node][child] && --indegree[child] == 0) queue[tail++] = child;
    }
    if (tail != count) return -1;
    bool visited[max_nodes]{};
    Event events[max_events];
    std::size_t event_count = 0;
    std::int32_t next_order = 0;
    if (!visit_node(static_cast<std::size_t>(raw_start), count, adjacent, predecessors, visited,
                    events, event_count, next_order)) return -1;
    const auto byte_count = 12 * event_count;
    if (output == nullptr || output_capacity < byte_count) return -2;
    for (std::size_t i = 0; i < event_count; ++i) {
        write_i32_le(output, 12 * i, events[i].type);
        write_i32_le(output, 12 * i + 4, events[i].node);
        write_i32_le(output, 12 * i + 8, events[i].order);
    }
    return static_cast<std::int64_t>(byte_count);
}
