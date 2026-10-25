#include <stddef.h>
#include <stdint.h>

/* Implicitly traverse the uniformly black Toronto quadtree. */
static int64_t visit_cells(int64_t x, int64_t y, int64_t span,
                           int64_t grid, int64_t edge) {
    if (span == 1) {
        int64_t perimeter = 0;
        if (x == 0) perimeter += edge;
        if (x + 1 == grid) perimeter += edge;
        if (y == 0) perimeter += edge;
        if (y + 1 == grid) perimeter += edge;
        return perimeter;
    }

    const int64_t half = span / 2;
    return visit_cells(x, y, half, grid, edge) +
           visit_cells(x + half, y, half, grid, edge) +
           visit_cells(x, y + half, half, grid, edge) +
           visit_cells(x + half, y + half, half, grid, edge);
}

int64_t olden_perimeter(const int64_t *values, size_t length) {
    if (values == NULL || length != 1) return -1;
    const int64_t level = values[0];
    if (level < 9 || level > 11) return -1;

    int64_t grid = 1;
    for (int64_t i = 0; i < level; ++i) grid *= 2;
    const int64_t edge = 4096 / grid;
    return visit_cells(0, 0, grid, grid, edge);
}
