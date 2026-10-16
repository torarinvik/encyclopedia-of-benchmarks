#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_nodes = 64;
constexpr std::size_t max_edges = 94;
constexpr std::size_t max_input_length = 4 + max_nodes + 2 * max_edges;
constexpr std::size_t max_output_bytes = 128;
}

extern "C" std::int64_t depth_first_search_target_route(
    const std::int64_t *values, std::size_t length, std::uint8_t *output,
    std::size_t output_capacity) noexcept
{
    if (values == nullptr || length < 5 || length > max_input_length) return -2;
    if (values[0] < 1 || values[0] > static_cast<std::int64_t>(max_nodes)
        || values[1] < 0 || values[1] > 255 || values[2] < 0 || values[2] > 255) return -2;
    const auto node_count = static_cast<std::size_t>(values[0]);
    const auto start_label = values[1];
    const auto target_label = values[2];
    const auto edge_count_position = 3 + node_count;
    if (edge_count_position >= length) return -2;

    std::int64_t labels[max_nodes];
    auto start_index = node_count;
    for (std::size_t index = 0; index < node_count; ++index) {
        const auto label = values[3 + index];
        if (label < 0 || label > 255) return -2;
        for (std::size_t prior = 0; prior < index; ++prior) {
            if (labels[prior] == label) return -2;
        }
        labels[index] = label;
        if (label == start_label) start_index = index;
    }
    if (start_index == node_count) return -2;

    const auto edge_count_value = values[edge_count_position];
    if (edge_count_value < 0 || edge_count_value > static_cast<std::int64_t>(max_edges)) return -2;
    const auto edge_count = static_cast<std::size_t>(edge_count_value);
    if (length != edge_count_position + 1 + 2 * edge_count) return -2;

    std::uint64_t adjacency[max_nodes] = {};
    for (std::size_t edge = 0; edge < edge_count; ++edge) {
        const auto left_label = values[edge_count_position + 1 + 2 * edge];
        const auto right_label = values[edge_count_position + 2 + 2 * edge];
        auto left = node_count;
        auto right = node_count;
        for (std::size_t index = 0; index < node_count; ++index) {
            if (labels[index] == left_label) left = index;
            if (labels[index] == right_label) right = index;
        }
        if (left == node_count || right == node_count) return -2;
        adjacency[left] |= UINT64_C(1) << right;
        adjacency[right] |= UINT64_C(1) << left;
    }

    std::size_t stack[max_nodes];
    std::size_t stack_length = 1;
    stack[0] = start_index;
    std::uint8_t route[max_output_bytes];
    std::size_t route_length = 0;
    while (stack_length != 0) {
        const auto current = stack[--stack_length];
        if (route_length == max_output_bytes) return -2;
        route[route_length++] = static_cast<std::uint8_t>(labels[current]);
        for (std::size_t neighbor = 0; neighbor < node_count; ++neighbor) {
            const auto bit = UINT64_C(1) << neighbor;
            if ((adjacency[current] & bit) != 0) {
                std::size_t pending = 0;
                while (pending < stack_length && stack[pending] != neighbor) ++pending;
                if (pending == stack_length) stack[stack_length++] = neighbor;
            }
            adjacency[current] &= ~bit;
            adjacency[neighbor] &= ~(UINT64_C(1) << current);
        }
        if (labels[current] == target_label) {
            if (output_capacity < route_length || (route_length != 0 && output == nullptr)) return -2;
            for (std::size_t index = 0; index < route_length; ++index) output[index] = route[index];
            return static_cast<std::int64_t>(route_length);
        }
    }
    return 0;
}
