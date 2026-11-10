#include <cstddef>
#include <cstdint>

extern "C" std::int64_t minimum_path_cost_in_grid(const std::int64_t *input, std::size_t length)
{
    if (input == nullptr || length < 2 || input[0] < 1 || input[0] > 32 ||
        input[1] < 1 || input[1] > 32) return -1;
    const std::size_t rows = static_cast<std::size_t>(input[0]);
    const std::size_t columns = static_cast<std::size_t>(input[1]);
    const std::size_t cells = rows * columns;
    const std::size_t move_offset = 2 + cells;
    if (length != move_offset + cells * columns) return -1;
    for (std::size_t index = 0; index < cells; ++index)
        if (input[2 + index] < 0 || input[2 + index] >= static_cast<std::int64_t>(cells)) return -1;
    for (std::size_t index = 0; index < cells * columns; ++index)
        if (input[move_offset + index] < 1 || input[move_offset + index] > 100) return -1;

    constexpr std::uint32_t infinity = 65536;
    std::uint32_t costs[32] = {};
    std::uint32_t next_costs[32];
    for (std::size_t row = 0; row + 1 < rows; ++row) {
        for (std::size_t target = 0; target < columns; ++target) next_costs[target] = infinity;
        for (std::size_t column = 0; column < columns; ++column) {
            const std::size_t value = static_cast<std::size_t>(input[2 + row * columns + column]);
            const std::uint32_t base = costs[column] + static_cast<std::uint32_t>(value);
            for (std::size_t target = 0; target < columns; ++target) {
                const std::uint32_t candidate = base + static_cast<std::uint32_t>(input[move_offset + value * columns + target]);
                next_costs[target] = candidate < next_costs[target] ? candidate : next_costs[target];
            }
        }
        for (std::size_t column = 0; column < columns; ++column) costs[column] = next_costs[column];
    }
    std::uint32_t minimum = infinity;
    const std::size_t last_row = 2 + (rows - 1) * columns;
    for (std::size_t column = 0; column < columns; ++column) {
        const std::uint32_t candidate = costs[column] + static_cast<std::uint32_t>(input[last_row + column]);
        if (candidate < minimum) minimum = candidate;
    }
    return minimum;
}
