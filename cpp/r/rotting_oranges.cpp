#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_cells = 256;
constexpr std::size_t max_input_length = 259;
constexpr std::int64_t invalid_result = INT64_MIN;
}

extern "C" std::int64_t rotting_oranges(const std::int64_t *input, std::size_t length) {
    if (input == nullptr) return length == 0 ? 0 : invalid_result;
    if (length == 0) return 0;
    if (length < 2 || length > max_input_length) return invalid_result;

    const std::int64_t rows_value = input[0];
    const std::int64_t columns_value = input[1];
    if (rows_value == 0) return columns_value == 0 && length == 2 ? 0 : invalid_result;
    if (rows_value < 1 || rows_value > 16 || columns_value < 0 || columns_value > 16) {
        return invalid_result;
    }
    const std::size_t rows = static_cast<std::size_t>(rows_value);
    const std::size_t columns = static_cast<std::size_t>(columns_value);
    const std::size_t cell_count = rows * columns;
    if (length != 2 + cell_count) return invalid_result;

    std::uint8_t cells[max_cells];
    std::size_t queue[max_cells];
    std::uint16_t distance[max_cells] = {};
    std::size_t head = 0, tail = 0, fresh = 0, rotted = 0;
    for (std::size_t index = 0; index < cell_count; ++index) {
        const std::int64_t value = input[2 + index];
        if (value < 0 || value > 2) return invalid_result;
        cells[index] = static_cast<std::uint8_t>(value);
        if (value == 1) ++fresh;
        else if (value == 2) queue[tail++] = index;
    }
    if (columns == 0 || fresh == 0) return 0;

    std::uint16_t minutes = 0;
    while (head < tail) {
        const std::size_t index = queue[head++];
        const std::size_t row = index / columns;
        const std::size_t column = index % columns;
        const auto next_distance = static_cast<std::uint16_t>(distance[index] + 1);
        std::size_t neighbors[4];
        std::size_t neighbor_count = 0;
        if (row > 0) neighbors[neighbor_count++] = index - columns;
        if (column + 1 < columns) neighbors[neighbor_count++] = index + 1;
        if (row + 1 < rows) neighbors[neighbor_count++] = index + columns;
        if (column > 0) neighbors[neighbor_count++] = index - 1;
        for (std::size_t offset = 0; offset < neighbor_count; ++offset) {
            const std::size_t next = neighbors[offset];
            if (cells[next] != 1) continue;
            cells[next] = 2;
            distance[next] = next_distance;
            if (next_distance > minutes) minutes = next_distance;
            ++rotted;
            queue[tail++] = next;
        }
    }
    return rotted == fresh ? static_cast<std::int64_t>(minutes) : -1;
}
