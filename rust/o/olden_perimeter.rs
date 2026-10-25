fn visit_cells(x: i64, y: i64, span: i64, grid: i64, edge: i64) -> i64 {
    if span == 1 {
        let mut perimeter = 0;
        if x == 0 { perimeter += edge; }
        if x + 1 == grid { perimeter += edge; }
        if y == 0 { perimeter += edge; }
        if y + 1 == grid { perimeter += edge; }
        return perimeter;
    }

    let half = span / 2;
    visit_cells(x, y, half, grid, edge) +
        visit_cells(x + half, y, half, grid, edge) +
        visit_cells(x, y + half, half, grid, edge) +
        visit_cells(x + half, y + half, half, grid, edge)
}

#[no_mangle]
pub unsafe extern "C" fn olden_perimeter(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length != 1 { return -1; }
    let level = *values;
    if level < 9 || level > 11 { return -1; }

    let grid = 1_i64 << level;
    let edge = 4096 / grid;
    visit_cells(0, 0, grid, grid, edge)
}
