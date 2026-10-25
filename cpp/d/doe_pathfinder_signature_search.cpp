#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t max_nodes = 10;
constexpr std::int64_t max_edges = 100;
constexpr std::int64_t max_signature_length = 4;
constexpr std::int64_t max_label = 7;

bool search_leg(const std::int64_t *values, std::size_t edge_count, std::size_t labels_start,
                std::size_t signature_start, std::size_t signature_length, std::size_t node,
                std::size_t signature_index, std::uint16_t *visited) {
    const auto bit = static_cast<std::uint16_t>(1u << node);
    if ((*visited & bit) != 0) return false;
    *visited |= bit;

    const auto target_label = values[signature_start + signature_index];
    for (std::size_t edge = 0; edge < edge_count; ++edge) {
        if (static_cast<std::size_t>(values[3 + 2 * edge]) != node) continue;
        const auto target = static_cast<std::size_t>(values[4 + 2 * edge]);
        if (values[labels_start + target] != target_label) continue;
        if (signature_index + 1 == signature_length) return true;
        std::uint16_t next_visited = 0;
        if (search_leg(values, edge_count, labels_start, signature_start, signature_length,
                       target, signature_index + 1, &next_visited)) return true;
    }

    for (std::size_t edge = 0; edge < edge_count; ++edge) {
        if (static_cast<std::size_t>(values[3 + 2 * edge]) != node) continue;
        const auto target = static_cast<std::size_t>(values[4 + 2 * edge]);
        if (search_leg(values, edge_count, labels_start, signature_start, signature_length,
                       target, signature_index, visited)) return true;
    }
    return false;
}
}

extern "C" std::int64_t doe_pathfinder_signature_search(const std::int64_t *values,
                                                         std::size_t length) {
    if (values == nullptr || length < 3 || values[0] < 1 || values[0] > max_nodes ||
        values[1] < 0 || values[1] > max_edges || values[2] < 2 ||
        values[2] > max_signature_length) return -2;
    const auto node_count = static_cast<std::size_t>(values[0]);
    const auto edge_count = static_cast<std::size_t>(values[1]);
    const auto signature_length = static_cast<std::size_t>(values[2]);
    if (edge_count > node_count * node_count ||
        length != 3 + 2 * edge_count + node_count + signature_length) return -2;

    for (std::size_t edge = 0; edge < edge_count; ++edge) {
        const auto from = values[3 + 2 * edge];
        const auto to = values[4 + 2 * edge];
        if (from < 0 || from >= static_cast<std::int64_t>(node_count) ||
            to < 0 || to >= static_cast<std::int64_t>(node_count)) return -2;
        for (std::size_t previous = 0; previous < edge; ++previous)
            if (values[3 + 2 * previous] == from && values[4 + 2 * previous] == to)
                return -2;
    }
    const std::size_t labels_start = 3 + 2 * edge_count;
    const std::size_t signature_start = labels_start + node_count;
    for (std::size_t node = 0; node < node_count; ++node)
        if (values[labels_start + node] < -1 || values[labels_start + node] > max_label)
            return -2;
    for (std::size_t index = 0; index < signature_length; ++index)
        if (values[signature_start + index] < 0 || values[signature_start + index] > max_label)
            return -2;

    const auto first_label = values[signature_start];
    for (std::size_t node = 0; node < node_count; ++node) {
        if (values[labels_start + node] != first_label) continue;
        std::uint16_t visited = 0;
        if (search_leg(values, edge_count, labels_start, signature_start, signature_length,
                       node, 1, &visited)) return 1;
    }
    return 0;
}
