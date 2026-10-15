/* Return the size of the largest four-connected nonzero region. */
#include <array>
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t area_of_island(const std::int64_t *input,
                                        std::size_t length) noexcept
{
    constexpr std::size_t max_rows = 64;
    constexpr std::size_t max_columns = 64;
    constexpr std::size_t max_cells = max_rows * max_columns;
    if (input == nullptr || length < 2 || input[0] < 1 || input[0] > static_cast<std::int64_t>(max_rows) ||
        input[1] < 0 || input[1] > static_cast<std::int64_t>(max_columns)) return -1;
    const auto rows = static_cast<std::size_t>(input[0]);
    const auto columns = static_cast<std::size_t>(input[1]);
    const auto cells = rows * columns;
    if (length != cells + 2) return -1;

    std::array<std::uint8_t, max_cells> visited{};
    std::array<std::size_t, max_cells> stack{};
    std::size_t maximum_area = 0;
    for (std::size_t start = 0; start < cells; ++start) {
        if (input[2 + start] == 0 || visited[start]) continue;
        std::size_t top = 0, area = 0;
        visited[start] = 1;
        stack[top++] = start;
        while (top != 0) {
            const auto current = stack[--top];
            ++area;
            const auto row = current / columns;
            const auto column = current % columns;
            auto visit = [&](std::size_t neighbor) {
                if (!visited[neighbor] && input[2 + neighbor] != 0) {
                    visited[neighbor] = 1;
                    stack[top++] = neighbor;
                }
            };
            if (row > 0) visit(current - columns);
            if (column + 1 < columns) visit(current + 1);
            if (row + 1 < rows) visit(current + columns);
            if (column > 0) visit(current - 1);
        }
        if (area > maximum_area) maximum_area = area;
    }
    return static_cast<std::int64_t>(maximum_area);
}
