const MAX_CELLS: usize = 64;
const MAX_HITS: usize = 16;
const MAX_INPUT_LENGTH: usize = 100;

fn findRoot(parent: []i32, vertexInput: usize) usize {
    var vertex = vertexInput;
    while (@as(usize, @intCast(parent[vertex])) != vertex) {
        const next: usize = @intCast(parent[vertex]);
        parent[vertex] = parent[next];
        vertex = @intCast(parent[vertex]);
    }
    return vertex;
}

fn unite(parent: []i32, componentSize: []i32, left: usize, right: usize) void {
    var a = findRoot(parent, left);
    var b = findRoot(parent, right);
    if (a == b) return;
    if (componentSize[a] < componentSize[b]) {
        const temporary = a;
        a = b;
        b = temporary;
    }
    parent[b] = @intCast(a);
    componentSize[a] += componentSize[b];
}

fn buildDsu(grid: []const u8, rows: usize, columns: usize,
            parent: []i32, componentSize: []i32) void {
    const cells = rows * columns;
    for (0..cells) |cell| {
        parent[cell] = @intCast(cell);
        componentSize[cell] = @intCast(grid[cell]);
    }
    parent[cells] = @intCast(cells);
    componentSize[cells] = 0;
    for (0..cells) |cell| {
        if (grid[cell] == 0) continue;
        const row = cell / columns;
        const column = cell % columns;
        if (row == 0) unite(parent, componentSize, cell, cells);
        if (row > 0 and grid[cell - columns] != 0) unite(parent, componentSize, cell, cell - columns);
        if (column > 0 and grid[cell - 1] != 0) unite(parent, componentSize, cell, cell - 1);
    }
}

fn putI64Le(output: [*]u8, offset: usize, value: i32) void {
    const bits: u64 = @intCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

pub export fn bricks_falling_when_hit_reverse_dsu(
    input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize,
) i64 {
    if (input == null or length < 3 or length > MAX_INPUT_LENGTH) return -1;
    const rowValue = input[0];
    const columnValue = input[1];
    const hitValue = input[2];
    if (rowValue < 1 or rowValue > 8 or columnValue < 1 or columnValue > 8 or hitValue < 0 or hitValue > MAX_HITS) return -1;
    const rows: usize = @intCast(rowValue);
    const columns: usize = @intCast(columnValue);
    const cells = rows * columns;
    const hits: usize = @intCast(hitValue);
    if (hits > cells or length != 3 + cells + 2 * hits) return -1;

    var grid: [MAX_CELLS]u8 = @splat(0);
    var parent: [MAX_CELLS + 1]i32 = @splat(0);
    var componentSize: [MAX_CELLS + 1]i32 = @splat(0);
    for (0..cells) |cell| {
        const value = input[3 + cell];
        if (value != 0 and value != 1) return -1;
        grid[cell] = @intCast(value);
    }
    const hitStart = 3 + cells;
    for (0..hits) |index| {
        const row = input[hitStart + 2 * index];
        const column = input[hitStart + 2 * index + 1];
        if (row < 0 or row >= rowValue or column < 0 or column >= columnValue) return -1;
        for (0..index) |previous| {
            if (input[hitStart + 2 * previous] == row and input[hitStart + 2 * previous + 1] == column) return -1;
        }
    }

    buildDsu(grid[0..cells], rows, columns, parent[0 .. cells + 1], componentSize[0 .. cells + 1]);
    const roofRoot = findRoot(parent[0 .. cells + 1], cells);
    for (0..cells) |cell| {
        if (grid[cell] != 0 and findRoot(parent[0 .. cells + 1], cell) != roofRoot) return -1;
    }

    const required = hits * 8;
    if (capacity < required or (required != 0 and output == null)) return -2;
    if (hits == 0) return 0;
    for (0..hits) |index| {
        const row: usize = @intCast(input[hitStart + 2 * index]);
        const column: usize = @intCast(input[hitStart + 2 * index + 1]);
        grid[row * columns + column] = 0;
    }
    buildDsu(grid[0..cells], rows, columns, parent[0 .. cells + 1], componentSize[0 .. cells + 1]);

    for (0..hits) |reverse| {
        const index = hits - 1 - reverse;
        const row: usize = @intCast(input[hitStart + 2 * index]);
        const column: usize = @intCast(input[hitStart + 2 * index + 1]);
        const cell = row * columns + column;
        if (input[3 + cell] == 0) {
            putI64Le(output, index * 8, 0);
            continue;
        }
        const before = componentSize[findRoot(parent[0 .. cells + 1], cells)];
        grid[cell] = 1;
        parent[cell] = @intCast(cell);
        componentSize[cell] = 1;
        if (row == 0) unite(parent[0 .. cells + 1], componentSize[0 .. cells + 1], cell, cells);
        if (row > 0 and grid[cell - columns] != 0) unite(parent[0 .. cells + 1], componentSize[0 .. cells + 1], cell, cell - columns);
        if (row + 1 < rows and grid[cell + columns] != 0) unite(parent[0 .. cells + 1], componentSize[0 .. cells + 1], cell, cell + columns);
        if (column > 0 and grid[cell - 1] != 0) unite(parent[0 .. cells + 1], componentSize[0 .. cells + 1], cell, cell - 1);
        if (column + 1 < columns and grid[cell + 1] != 0) unite(parent[0 .. cells + 1], componentSize[0 .. cells + 1], cell, cell + 1);
        const after = componentSize[findRoot(parent[0 .. cells + 1], cells)];
        const fallen: i32 = if (after > before + 1) after - before - 1 else 0;
        putI64Le(output, index * 8, fallen);
    }
    return @intCast(required);
}
