#include <cstddef>
#include <cstdint>
#include <limits>

namespace {
constexpr std::size_t max_dimension = 8;
constexpr std::size_t max_cells = max_dimension * max_dimension;
constexpr std::size_t max_input_length = 5 + max_cells;
constexpr std::size_t max_output_values = 1 + max_cells;
void put_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    const std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t bidirectional_breadth_first_search(const std::int64_t *input, std::size_t length,
    std::uint8_t *output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 5 || length > max_input_length) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(max_dimension) || input[1] < 1 || input[1] > static_cast<std::int64_t>(max_dimension)) return -1;
    const auto rows = static_cast<std::size_t>(input[0]), cols = static_cast<std::size_t>(input[1]), cells = rows * cols;
    if (input[2] < 0 || input[2] >= static_cast<std::int64_t>(cells) || input[3] < 0 || input[3] >= static_cast<std::int64_t>(cells)) return -1;
    if (input[4] < 0 || input[4] > static_cast<std::int64_t>(cells) || length != 5 + static_cast<std::size_t>(input[4])) return -1;
    const auto start = static_cast<std::size_t>(input[2]), goal = static_cast<std::size_t>(input[3]), blocked_count = static_cast<std::size_t>(input[4]);
    bool blocked[max_cells] = {};
    for (std::size_t i = 0; i < blocked_count; ++i) {
        const auto value = input[5 + i];
        if (value < 0 || value >= static_cast<std::int64_t>(cells)) return -1;
        const auto cell = static_cast<std::size_t>(value);
        if (blocked[cell]) return -1;
        blocked[cell] = true;
    }
    if (blocked[start] || blocked[goal]) return -1;

    std::int64_t distance[2][max_cells], parent[2][max_cells];
    std::size_t queue[2][max_cells];
    std::size_t head[2] = {0, 0}, tail[2] = {1, 1};
    for (std::size_t side = 0; side < 2; ++side) for (std::size_t cell = 0; cell < cells; ++cell) distance[side][cell] = parent[side][cell] = -1;
    distance[0][start] = distance[1][goal] = 0;
    queue[0][0] = start;
    queue[1][0] = goal;
    std::int64_t meeting = start == goal ? static_cast<std::int64_t>(start) : -1;
    while (meeting < 0 && head[0] < tail[0] && head[1] < tail[1]) {
      for (std::size_t side = 0; side < 2; ++side) {
        if (meeting >= 0) break;
        const std::size_t layer_end = tail[side];
        while (head[side] < layer_end) {
            const auto node = queue[side][head[side]++];
            const auto row = node / cols, col = node % cols;
            for (std::size_t direction = 0; direction < 4; ++direction) {
                std::size_t neighbor = 0;
                bool valid = false;
                if (direction == 0 && row > 0) { neighbor = node - cols; valid = true; }
                else if (direction == 1 && col > 0) { neighbor = node - 1; valid = true; }
                else if (direction == 2 && row + 1 < rows) { neighbor = node + cols; valid = true; }
                else if (direction == 3 && col + 1 < cols) { neighbor = node + 1; valid = true; }
                if (!valid || blocked[neighbor] || distance[side][neighbor] != -1) continue;
                distance[side][neighbor] = distance[side][node] + 1;
                parent[side][neighbor] = static_cast<std::int64_t>(node);
                queue[side][tail++] = neighbor;
                if (distance[1 - side][neighbor] >= 0) { meeting = static_cast<std::int64_t>(neighbor); break; }
            }
            if (meeting >= 0) break;
        }
      }
    }
    std::int64_t result[max_output_values];
    std::size_t result_count = 1;
    if (meeting < 0) result[0] = 0;
    else {
        std::size_t reverse_path[max_cells], prefix_count = 0, path_count = 0;
        auto current = meeting;
        while (current >= 0) { reverse_path[prefix_count++] = static_cast<std::size_t>(current); if (static_cast<std::size_t>(current) == start) break; current = parent[0][static_cast<std::size_t>(current)]; }
        for (std::size_t i = 0; i < prefix_count; ++i) result[1 + path_count++] = static_cast<std::int64_t>(reverse_path[prefix_count - 1 - i]);
        current = parent[1][static_cast<std::size_t>(meeting)];
        while (current >= 0) { result[1 + path_count++] = current; current = parent[1][static_cast<std::size_t>(current)]; }
        result[0] = static_cast<std::int64_t>(path_count);
        result_count += path_count;
    }
    const std::size_t output_bytes = result_count * 8;
    if (output == nullptr || capacity < output_bytes) return -2;
    for (std::size_t i = 0; i < result_count; ++i) put_i64_le(output, i * 8, result[i]);
    return static_cast<std::int64_t>(output_bytes);
}
