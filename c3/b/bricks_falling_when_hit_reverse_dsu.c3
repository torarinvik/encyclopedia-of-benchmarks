module bricks_falling_when_hit_reverse_dsu;

const usz MAX_HITS = 16;
const usz MAX_INPUT = 100;

fn int find_root(int* parent, int vertex) {
    while (parent[vertex] != vertex) {
        parent[vertex] = parent[parent[vertex]];
        vertex = parent[vertex];
    }
    return vertex;
}

fn void unite(int* parent, int* component_size, int left, int right) {
    int a = find_root(parent, left), b = find_root(parent, right);
    if (a == b) return;
    if (component_size[a] < component_size[b]) { int temporary = a; a = b; b = temporary; }
    parent[b] = a;
    component_size[a] += component_size[b];
}

fn void build_dsu(char* grid, usz rows, usz columns, int* parent, int* component_size) {
    usz cells = rows * columns;
    for (usz cell = 0; cell < cells; cell++) {
        parent[cell] = (int)cell;
        component_size[cell] = (int)grid[cell];
    }
    parent[cells] = (int)cells;
    component_size[cells] = 0;
    for (usz cell = 0; cell < cells; cell++) {
        if (grid[cell] == 0) continue;
        usz row = cell / columns, column = cell % columns;
        if (row == 0) unite(parent, component_size, (int)cell, (int)cells);
        if (row > 0 && grid[cell - columns] != 0) unite(parent, component_size, (int)cell, (int)(cell - columns));
        if (column > 0 && grid[cell - 1] != 0) unite(parent, component_size, (int)cell, (int)(cell - 1));
    }
}

fn void put_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long bricks_falling_when_hit_reverse_dsu(long* input, usz length,
        char* output, usz capacity) @export("bricks_falling_when_hit_reverse_dsu") {
    if (input == null || length < 3 || length > MAX_INPUT) return -1;
    long row_value = input[0], column_value = input[1], hit_value = input[2];
    if (row_value < 1 || row_value > 8 || column_value < 1 || column_value > 8 || hit_value < 0 || hit_value > MAX_HITS) return -1;
    usz rows = (usz)row_value, columns = (usz)column_value, cells = rows * columns;
    usz hits = (usz)hit_value;
    if (hits > cells || length != 3 + cells + 2 * hits) return -1;

    char[64] grid;
    int[65] parent;
    int[65] component_size;
    for (usz cell = 0; cell < cells; cell++) {
        long value = input[3 + cell];
        if (value != 0 && value != 1) return -1;
        grid[cell] = (char)value;
    }
    usz hit_start = 3 + cells;
    for (usz index = 0; index < hits; index++) {
        long row = input[hit_start + 2 * index], column = input[hit_start + 2 * index + 1];
        if (row < 0 || row >= row_value || column < 0 || column >= column_value) return -1;
        for (usz previous = 0; previous < index; previous++)
            if (input[hit_start + 2 * previous] == row && input[hit_start + 2 * previous + 1] == column) return -1;
    }

    build_dsu(&grid[0], rows, columns, &parent[0], &component_size[0]);
    int roof_root = find_root(&parent[0], (int)cells);
    for (usz cell = 0; cell < cells; cell++)
        if (grid[cell] != 0 && find_root(&parent[0], (int)cell) != roof_root) return -1;

    usz required = hits * 8;
    if (capacity < required || (required != 0 && output == null)) return -2;
    if (hits == 0) return 0;
    for (usz index = 0; index < hits; index++) {
        usz row = (usz)input[hit_start + 2 * index];
        usz column = (usz)input[hit_start + 2 * index + 1];
        grid[row * columns + column] = 0;
    }
    build_dsu(&grid[0], rows, columns, &parent[0], &component_size[0]);

    for (usz reverse = hits; reverse > 0; reverse--) {
        usz index = reverse - 1;
        usz row = (usz)input[hit_start + 2 * index];
        usz column = (usz)input[hit_start + 2 * index + 1];
        usz cell = row * columns + column;
        if (input[3 + cell] == 0) { put_i64_le(output, index * 8, 0); continue; }
        int before = component_size[find_root(&parent[0], (int)cells)];
        grid[cell] = 1;
        parent[cell] = (int)cell;
        component_size[cell] = 1;
        if (row == 0) unite(&parent[0], &component_size[0], (int)cell, (int)cells);
        if (row > 0 && grid[cell - columns] != 0) unite(&parent[0], &component_size[0], (int)cell, (int)(cell - columns));
        if (row + 1 < rows && grid[cell + columns] != 0) unite(&parent[0], &component_size[0], (int)cell, (int)(cell + columns));
        if (column > 0 && grid[cell - 1] != 0) unite(&parent[0], &component_size[0], (int)cell, (int)(cell - 1));
        if (column + 1 < columns && grid[cell + 1] != 0) unite(&parent[0], &component_size[0], (int)cell, (int)(cell + 1));
        int after = component_size[find_root(&parent[0], (int)cells)];
        int fallen = after > before + 1 ? after - before - 1 : 0;
        put_i64_le(output, index * 8, (long)fallen);
    }
    return (long)required;
}
