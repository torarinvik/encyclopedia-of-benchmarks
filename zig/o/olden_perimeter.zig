fn visitCells(x: i64, y: i64, span: i64, grid: i64, edge: i64) i64 {
    if (span == 1) {
        var perimeter: i64 = 0;
        if (x == 0) perimeter += edge;
        if (x + 1 == grid) perimeter += edge;
        if (y == 0) perimeter += edge;
        if (y + 1 == grid) perimeter += edge;
        return perimeter;
    }

    const half = span / 2;
    return visitCells(x, y, half, grid, edge) +
        visitCells(x + half, y, half, grid, edge) +
        visitCells(x, y + half, half, grid, edge) +
        visitCells(x + half, y + half, half, grid, edge);
}

export fn olden_perimeter(values: ?[*]const i64, length: usize) i64 {
    if (values == null or length != 1) return -1;
    const level = values.?[0];
    if (level < 9 or level > 11) return -1;

    const grid: i64 = @as(i64, 1) << @intCast(level);
    const edge = 4096 / grid;
    return visitCells(0, 0, grid, grid, edge);
}
