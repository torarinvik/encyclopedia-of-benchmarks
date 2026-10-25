module olden_perimeter;

fn long visit_cells(long x, long y, long span, long grid, long edge) {
    if (span == 1) {
        long perimeter = 0;
        if (x == 0) perimeter += edge;
        if (x + 1 == grid) perimeter += edge;
        if (y == 0) perimeter += edge;
        if (y + 1 == grid) perimeter += edge;
        return perimeter;
    }
    long half = span / 2;
    return visit_cells(x, y, half, grid, edge) +
           visit_cells(x + half, y, half, grid, edge) +
           visit_cells(x, y + half, half, grid, edge) +
           visit_cells(x + half, y + half, half, grid, edge);
}

fn long olden_perimeter(long* values, usz length) @export("olden_perimeter") {
    if (values == null || length != 1) return -1;
    long level = values[0];
    if (level < 9 || level > 11) return -1;
    long grid = 1;
    for (long i = 0; i < level; i++) grid *= 2;
    long edge = 4096 / grid;
    return visit_cells(0, 0, grid, grid, edge);
}
