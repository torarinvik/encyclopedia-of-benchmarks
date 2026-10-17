#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_vertices = 16;
constexpr std::size_t max_neighbors = 64;
constexpr std::size_t max_depth = 8;
constexpr std::size_t max_valid_input_length = 4 + 2 * max_vertices + max_neighbors;
constexpr std::size_t max_parseable_input_length = max_valid_input_length + 1;
constexpr std::size_t max_path_length = max_depth + 1;
constexpr std::size_t max_output_values = 3 + max_path_length;

void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
} // namespace

extern "C" std::int64_t iddfs(const std::int64_t *values, std::size_t length,
                               std::uint8_t *output, std::size_t output_capacity) noexcept {
    if (!values || length < 4 || length > max_parseable_input_length) return -1;
    const auto raw_start = values[0];
    const auto raw_target = values[1];
    const auto raw_depth = values[2];
    const auto raw_entries = values[3];
    if (raw_start < 1 || raw_start > static_cast<std::int64_t>(max_vertices) ||
        raw_target < 1 || raw_target > static_cast<std::int64_t>(max_vertices) ||
        raw_depth < 0 || raw_depth > static_cast<std::int64_t>(max_depth) ||
        raw_entries < 0 || raw_entries > static_cast<std::int64_t>(max_vertices)) return -1;
    const auto start = static_cast<int>(raw_start);
    const auto target = static_cast<int>(raw_target);
    const auto depth_limit = static_cast<std::size_t>(raw_depth);
    const auto entry_count = static_cast<std::size_t>(raw_entries);

    std::array<std::array<std::int32_t, max_neighbors>, max_vertices> adjacency{};
    std::array<std::size_t, max_vertices> degree_count{};
    std::array<bool, max_vertices> named{};
    std::size_t max_vertex = 0;
    std::size_t total_neighbors = 0;
    std::size_t cursor = 4;
    for (std::size_t entry = 0; entry < entry_count; ++entry) {
        if (cursor + 2 > length) return -1;
        const auto raw_vertex = values[cursor++];
        const auto raw_degree = values[cursor++];
        if (raw_vertex < 1 || raw_vertex > static_cast<std::int64_t>(max_vertices) ||
            raw_degree < 0 || raw_degree > static_cast<std::int64_t>(max_neighbors)) return -1;
        const auto vertex = static_cast<std::size_t>(raw_vertex);
        const auto degree = static_cast<std::size_t>(raw_degree);
        if (named[vertex - 1] || degree > length - cursor || total_neighbors + degree > max_neighbors) return -1;
        named[vertex - 1] = true;
        if (vertex > max_vertex) max_vertex = vertex;
        total_neighbors += degree;
        for (std::size_t index = 0; index < degree; ++index) {
            const auto raw_neighbor = values[cursor++];
            if (raw_neighbor < -static_cast<std::int64_t>(max_vertices) ||
                raw_neighbor > static_cast<std::int64_t>(max_vertices)) return -1;
            if (raw_neighbor > static_cast<std::int64_t>(max_vertex)) max_vertex = static_cast<std::size_t>(raw_neighbor);
            if (raw_neighbor >= 1) adjacency[vertex - 1][degree_count[vertex - 1]++] = static_cast<std::int32_t>(raw_neighbor);
        }
    }
    if (cursor != length) return -1;
    if (max_vertex != 0 && (static_cast<std::size_t>(start) > max_vertex || static_cast<std::size_t>(target) > max_vertex)) return -1;

    std::array<std::int64_t, max_path_length> path{};
    std::array<std::size_t, max_path_length> next_neighbor{};
    std::size_t path_length = 0;
    std::size_t found_depth = 0;
    bool found = false;
    if (max_vertex != 0) {
        for (std::size_t limit = 0; limit <= depth_limit && !found; ++limit) {
            path_length = 1;
            path[0] = start;
            next_neighbor[0] = 0;
            if (start == target) {
                found = true;
                found_depth = 0;
                break;
            }
            while (path_length != 0 && !found) {
                const auto frame = path_length - 1;
                const auto current = static_cast<std::size_t>(path[frame]);
                if (frame >= limit || next_neighbor[frame] >= degree_count[current - 1]) {
                    --path_length;
                    continue;
                }
                const auto neighbor = adjacency[current - 1][next_neighbor[frame]++];
                std::size_t prior = 0;
                while (prior < path_length && path[prior] != neighbor) ++prior;
                if (prior != path_length) continue;
                path[path_length] = neighbor;
                ++path_length;
                if (neighbor == target) {
                    found = true;
                    found_depth = path_length - 1;
                } else {
                    next_neighbor[path_length - 1] = 0;
                }
            }
        }
    }

    std::array<std::int64_t, max_output_values> result{};
    std::size_t result_count = 3;
    result[0] = found ? 1 : 0;
    result[1] = found ? static_cast<std::int64_t>(found_depth) : -1;
    result[2] = found ? static_cast<std::int64_t>(path_length) : 0;
    if (found) {
        result_count += path_length;
        for (std::size_t index = 0; index < path_length; ++index) result[3 + index] = path[index];
    }
    const auto required = result_count * 8;
    if (!output || output_capacity < required) return -2;
    for (std::size_t index = 0; index < result_count; ++index) store_i64_le(output, 8 * index, result[index]);
    return static_cast<std::int64_t>(required);
}
