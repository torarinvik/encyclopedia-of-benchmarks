/* Directed one-target Bellman-Ford with Go map last-write edge normalization. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_VERTICES = 64;
constexpr std::size_t MAX_INPUT_EDGES = 256;
constexpr std::size_t MAX_NORMALIZED_EDGES = 128;
constexpr std::int64_t MAX_WEIGHT = 1'000;
constexpr std::size_t RECORD_BYTES = 24;

std::int64_t write_record(std::uint8_t *output, std::size_t capacity, std::int64_t status,
                          std::int64_t reachable, std::int64_t distance) noexcept {
    if (output == nullptr || capacity < RECORD_BYTES) return -2;
    const std::int64_t record[3] = {status, reachable, distance};
    for (std::size_t field = 0; field < 3; ++field) {
        const auto bits = static_cast<std::uint64_t>(record[field]);
        for (std::size_t byte = 0; byte < 8; ++byte)
            output[field * 8 + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
    }
    return RECORD_BYTES;
}
}

extern "C" std::int64_t bellman_ford_pair(const std::int64_t *input, std::size_t length,
                                           std::uint8_t *output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 4) return -1;
    const auto vertices_value = input[0];
    const auto input_edges_value = input[1];
    const auto source_value = input[2];
    const auto target_value = input[3];
    if (vertices_value < 1 || vertices_value > static_cast<std::int64_t>(MAX_VERTICES) ||
        input_edges_value < 0 || input_edges_value > static_cast<std::int64_t>(MAX_INPUT_EDGES)) return -1;
    const auto vertices = static_cast<std::size_t>(vertices_value);
    const auto input_edges = static_cast<std::size_t>(input_edges_value);
    if (source_value < 0 || source_value >= vertices_value || target_value < 0 || target_value >= vertices_value ||
        length != 4 + 3 * input_edges) return -1;

    std::int64_t matrix_weights[MAX_VERTICES * MAX_VERTICES]{};
    std::uint8_t matrix_present[MAX_VERTICES * MAX_VERTICES]{};
    std::size_t normalized_count = 0;
    for (std::size_t edge = 0; edge < input_edges; ++edge) {
        const auto from_value = input[4 + 3 * edge];
        const auto to_value = input[5 + 3 * edge];
        const auto weight = input[6 + 3 * edge];
        if (from_value < 0 || from_value >= vertices_value || to_value < 0 || to_value >= vertices_value ||
            weight < -MAX_WEIGHT || weight > MAX_WEIGHT) return -1;
        const auto key = static_cast<std::size_t>(from_value) * vertices + static_cast<std::size_t>(to_value);
        if (!matrix_present[key]) {
            matrix_present[key] = 1;
            if (++normalized_count > MAX_NORMALIZED_EDGES) return -1;
        }
        matrix_weights[key] = weight;
    }

    std::size_t from[MAX_NORMALIZED_EDGES], to[MAX_NORMALIZED_EDGES];
    std::int64_t weight[MAX_NORMALIZED_EDGES];
    std::size_t edge_count = 0;
    for (std::size_t origin = 0; origin < vertices; ++origin) {
        for (std::size_t destination = 0; destination < vertices; ++destination) {
            const auto key = origin * vertices + destination;
            if (!matrix_present[key]) continue;
            from[edge_count] = origin;
            to[edge_count] = destination;
            weight[edge_count] = matrix_weights[key];
            ++edge_count;
        }
    }

    const auto source = static_cast<std::size_t>(source_value);
    const auto target = static_cast<std::size_t>(target_value);
    std::int64_t distance[MAX_VERTICES]{};
    std::uint8_t reachable[MAX_VERTICES]{};
    reachable[source] = 1;
    for (std::size_t round = 0; round < vertices; ++round) {
        bool changed = false;
        for (std::size_t edge = 0; edge < edge_count; ++edge) {
            if (!reachable[from[edge]]) continue;
            const auto candidate = distance[from[edge]] + weight[edge];
            if (!reachable[to[edge]] || candidate < distance[to[edge]]) {
                distance[to[edge]] = candidate;
                reachable[to[edge]] = 1;
                changed = true;
            }
        }
        if (!changed) break;
    }
    for (std::size_t edge = 0; edge < edge_count; ++edge) {
        if (reachable[from[edge]] && distance[to[edge]] > distance[from[edge]] + weight[edge])
            return write_record(output, capacity, -1, 0, 0);
    }
    return write_record(output, capacity, 0, reachable[target], reachable[target] ? distance[target] : 0);
}
