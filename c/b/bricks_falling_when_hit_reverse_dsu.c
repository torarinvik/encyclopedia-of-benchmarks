#include <stddef.h>
#include <stdint.h>

enum { MAX_ROWS = 8, MAX_COLUMNS = 8, MAX_CELLS = 64,
       MAX_HITS = 16, MAX_INPUT = 100 };

static int32_t find_root(int32_t parent[MAX_CELLS + 1], int32_t vertex) {
    while (parent[vertex] != vertex) {
        parent[vertex] = parent[parent[vertex]];
        vertex = parent[vertex];
    }
    return vertex;
}

static void unite(int32_t parent[MAX_CELLS + 1], int32_t size[MAX_CELLS + 1],
                  int32_t left, int32_t right) {
    int32_t a = find_root(parent, left), b = find_root(parent, right);
    if (a == b) return;
    if (size[a] < size[b]) { int32_t temporary = a; a = b; b = temporary; }
    parent[b] = a;
    size[a] += size[b];
}

static void build_dsu(const uint8_t grid[MAX_CELLS], size_t rows, size_t columns,
                      int32_t parent[MAX_CELLS + 1], int32_t size[MAX_CELLS + 1]) {
    const size_t cells = rows * columns;
    for (size_t cell = 0; cell < cells; ++cell) {
        parent[cell] = (int32_t)cell;
        size[cell] = grid[cell];
    }
    parent[cells] = (int32_t)cells;
    size[cells] = 0;
    for (size_t cell = 0; cell < cells; ++cell) {
        if (grid[cell] == 0) continue;
        const size_t row = cell / columns, column = cell % columns;
        if (row == 0) unite(parent, size, (int32_t)cell, (int32_t)cells);
        if (row > 0 && grid[cell - columns] != 0)
            unite(parent, size, (int32_t)cell, (int32_t)(cell - columns));
        if (column > 0 && grid[cell - 1] != 0)
            unite(parent, size, (int32_t)cell, (int32_t)(cell - 1));
    }
}

static void put_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t bricks_falling_when_hit_reverse_dsu(const int64_t *input, size_t length,
                                             uint8_t *output, size_t capacity) {
    if (input == NULL || length < 3 || length > MAX_INPUT) return -1;
    const int64_t row_value = input[0], column_value = input[1], hit_value = input[2];
    if (row_value < 1 || row_value > MAX_ROWS || column_value < 1 ||
        column_value > MAX_COLUMNS || hit_value < 0 || hit_value > MAX_HITS) return -1;
    const size_t rows = (size_t)row_value, columns = (size_t)column_value;
    const size_t cells = rows * columns, hits = (size_t)hit_value;
    if (hits > cells || length != 3 + cells + 2 * hits) return -1;

    uint8_t grid[MAX_CELLS] = {0};
    int32_t parent[MAX_CELLS + 1], component_size[MAX_CELLS + 1];
    for (size_t cell = 0; cell < cells; ++cell) {
        const int64_t value = input[3 + cell];
        if (value != 0 && value != 1) return -1;
        grid[cell] = (uint8_t)value;
    }
    const size_t hit_start = 3 + cells;
    for (size_t index = 0; index < hits; ++index) {
        const int64_t row = input[hit_start + 2 * index];
        const int64_t column = input[hit_start + 2 * index + 1];
        if (row < 0 || row >= row_value || column < 0 || column >= column_value) return -1;
        for (size_t previous = 0; previous < index; ++previous) {
            if (input[hit_start + 2 * previous] == row &&
                input[hit_start + 2 * previous + 1] == column) return -1;
        }
    }

    build_dsu(grid, rows, columns, parent, component_size);
    const int32_t roof_root = find_root(parent, (int32_t)cells);
    for (size_t cell = 0; cell < cells; ++cell)
        if (grid[cell] != 0 && find_root(parent, (int32_t)cell) != roof_root) return -1;

    const size_t required = hits * 8;
    if (capacity < required || (required != 0 && output == NULL)) return -2;
    if (hits == 0) return 0;

    for (size_t index = 0; index < hits; ++index) {
        const size_t row = (size_t)input[hit_start + 2 * index];
        const size_t column = (size_t)input[hit_start + 2 * index + 1];
        grid[row * columns + column] = 0;
    }
    build_dsu(grid, rows, columns, parent, component_size);
    for (size_t reverse = hits; reverse > 0; --reverse) {
        const size_t index = reverse - 1;
        const size_t row = (size_t)input[hit_start + 2 * index];
        const size_t column = (size_t)input[hit_start + 2 * index + 1];
        const size_t cell = row * columns + column;
        if (input[3 + cell] == 0) {
            put_i64_le(output, index * 8, 0);
            continue;
        }
        const int32_t before = component_size[find_root(parent, (int32_t)cells)];
        grid[cell] = 1;
        parent[cell] = (int32_t)cell;
        component_size[cell] = 1;
        if (row == 0) unite(parent, component_size, (int32_t)cell, (int32_t)cells);
        if (row > 0 && grid[cell - columns] != 0)
            unite(parent, component_size, (int32_t)cell, (int32_t)(cell - columns));
        if (row + 1 < rows && grid[cell + columns] != 0)
            unite(parent, component_size, (int32_t)cell, (int32_t)(cell + columns));
        if (column > 0 && grid[cell - 1] != 0)
            unite(parent, component_size, (int32_t)cell, (int32_t)(cell - 1));
        if (column + 1 < columns && grid[cell + 1] != 0)
            unite(parent, component_size, (int32_t)cell, (int32_t)(cell + 1));
        const int32_t after = component_size[find_root(parent, (int32_t)cells)];
        const int32_t fallen = after > before + 1 ? after - before - 1 : 0;
        put_i64_le(output, index * 8, fallen);
    }
    return (int64_t)required;
}
