#include <array>
#include <cstddef>
#include <cstdint>
#include <utility>

namespace {
constexpr std::size_t max_cells = 64;

std::int32_t find_root(std::array<std::int32_t, 65>& parent, std::int32_t vertex) {
    while (parent[static_cast<std::size_t>(vertex)] != vertex) {
        auto& slot = parent[static_cast<std::size_t>(vertex)];
        slot = parent[static_cast<std::size_t>(slot)];
        vertex = slot;
    }
    return vertex;
}

void unite(std::array<std::int32_t, 65>& parent,
           std::array<std::int32_t, 65>& size,
           std::int32_t left, std::int32_t right) {
    auto a = find_root(parent, left), b = find_root(parent, right);
    if (a == b) return;
    if (size[static_cast<std::size_t>(a)] < size[static_cast<std::size_t>(b)]) std::swap(a, b);
    parent[static_cast<std::size_t>(b)] = a;
    size[static_cast<std::size_t>(a)] += size[static_cast<std::size_t>(b)];
}

void build_dsu(const std::array<std::uint8_t, max_cells>& grid,
               std::size_t rows, std::size_t columns,
               std::array<std::int32_t, 65>& parent,
               std::array<std::int32_t, 65>& size) {
    const auto cells = rows * columns;
    for (std::size_t cell = 0; cell < cells; ++cell) {
        parent[cell] = static_cast<std::int32_t>(cell);
        size[cell] = grid[cell];
    }
    parent[cells] = static_cast<std::int32_t>(cells);
    size[cells] = 0;
    for (std::size_t cell = 0; cell < cells; ++cell) {
        if (grid[cell] == 0) continue;
        const auto row = cell / columns, column = cell % columns;
        if (row == 0) unite(parent, size, static_cast<std::int32_t>(cell), static_cast<std::int32_t>(cells));
        if (row > 0 && grid[cell - columns]) unite(parent, size, static_cast<std::int32_t>(cell), static_cast<std::int32_t>(cell - columns));
        if (column > 0 && grid[cell - 1]) unite(parent, size, static_cast<std::int32_t>(cell), static_cast<std::int32_t>(cell - 1));
    }
}

void put_i64_le(std::uint8_t* output, std::size_t offset, std::int32_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t bricks_falling_when_hit_reverse_dsu(
    const std::int64_t* input, std::size_t length, std::uint8_t* output,
    std::size_t capacity) {
    if (input == nullptr || length < 3 || length > 100) return -1;
    const auto row_value = input[0], column_value = input[1], hit_value = input[2];
    if (row_value < 1 || row_value > 8 || column_value < 1 || column_value > 8 || hit_value < 0 || hit_value > 16) return -1;
    const auto rows = static_cast<std::size_t>(row_value);
    const auto columns = static_cast<std::size_t>(column_value);
    const auto cells = rows * columns;
    const auto hits = static_cast<std::size_t>(hit_value);
    if (hits > cells || length != 3 + cells + 2 * hits) return -1;

    std::array<std::uint8_t, max_cells> grid{};
    std::array<std::int32_t, 65> parent{};
    std::array<std::int32_t, 65> component_size{};
    for (std::size_t cell = 0; cell < cells; ++cell) {
        const auto value = input[3 + cell];
        if (value != 0 && value != 1) return -1;
        grid[cell] = static_cast<std::uint8_t>(value);
    }
    const auto hit_start = 3 + cells;
    for (std::size_t i = 0; i < hits; ++i) {
        const auto row = input[hit_start + 2 * i];
        const auto column = input[hit_start + 2 * i + 1];
        if (row < 0 || row >= row_value || column < 0 || column >= column_value) return -1;
        for (std::size_t j = 0; j < i; ++j)
            if (input[hit_start + 2 * j] == row && input[hit_start + 2 * j + 1] == column) return -1;
    }

    build_dsu(grid, rows, columns, parent, component_size);
    const auto roof_root = find_root(parent, static_cast<std::int32_t>(cells));
    for (std::size_t cell = 0; cell < cells; ++cell)
        if (grid[cell] && find_root(parent, static_cast<std::int32_t>(cell)) != roof_root) return -1;

    const auto required = hits * 8;
    if (capacity < required || (required != 0 && output == nullptr)) return -2;
    if (hits == 0) return 0;
    for (std::size_t i = 0; i < hits; ++i) {
        const auto row = static_cast<std::size_t>(input[hit_start + 2 * i]);
        const auto column = static_cast<std::size_t>(input[hit_start + 2 * i + 1]);
        grid[row * columns + column] = 0;
    }
    build_dsu(grid, rows, columns, parent, component_size);

    for (std::size_t reverse = hits; reverse > 0; --reverse) {
        const auto index = reverse - 1;
        const auto row = static_cast<std::size_t>(input[hit_start + 2 * index]);
        const auto column = static_cast<std::size_t>(input[hit_start + 2 * index + 1]);
        const auto cell = row * columns + column;
        if (input[3 + cell] == 0) { put_i64_le(output, index * 8, 0); continue; }
        const auto before = component_size[static_cast<std::size_t>(find_root(parent, static_cast<std::int32_t>(cells)))];
        grid[cell] = 1;
        parent[cell] = static_cast<std::int32_t>(cell);
        component_size[cell] = 1;
        if (row == 0) unite(parent, component_size, static_cast<std::int32_t>(cell), static_cast<std::int32_t>(cells));
        if (row > 0 && grid[cell - columns]) unite(parent, component_size, static_cast<std::int32_t>(cell), static_cast<std::int32_t>(cell - columns));
        if (row + 1 < rows && grid[cell + columns]) unite(parent, component_size, static_cast<std::int32_t>(cell), static_cast<std::int32_t>(cell + columns));
        if (column > 0 && grid[cell - 1]) unite(parent, component_size, static_cast<std::int32_t>(cell), static_cast<std::int32_t>(cell - 1));
        if (column + 1 < columns && grid[cell + 1]) unite(parent, component_size, static_cast<std::int32_t>(cell), static_cast<std::int32_t>(cell + 1));
        const auto after = component_size[static_cast<std::size_t>(find_root(parent, static_cast<std::int32_t>(cells)))];
        const auto fallen = after > before + 1 ? after - before - 1 : 0;
        put_i64_le(output, index * 8, fallen);
    }
    return static_cast<std::int64_t>(required);
}
