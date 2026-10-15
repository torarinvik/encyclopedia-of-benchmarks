/// Return the size of the largest four-connected nonzero region.
#[no_mangle]
pub extern "C" fn area_of_island(input: *const i64, length: usize) -> i64 {
    const MAX_ROWS: usize = 64;
    const MAX_COLUMNS: usize = 64;
    const MAX_CELLS: usize = MAX_ROWS * MAX_COLUMNS;
    if input.is_null() || length < 2 {
        return -1;
    }
    let rows_value = unsafe { *input };
    let columns_value = unsafe { *input.add(1) };
    if !(1..=MAX_ROWS as i64).contains(&rows_value) ||
        !(0..=MAX_COLUMNS as i64).contains(&columns_value) {
        return -1;
    }
    let rows = rows_value as usize;
    let columns = columns_value as usize;
    let cells = rows * columns;
    if length != cells + 2 {
        return -1;
    }
    let input = unsafe { std::slice::from_raw_parts(input, length) };

    let mut visited = [false; MAX_CELLS];
    let mut stack = [0usize; MAX_CELLS];
    let mut maximum_area = 0usize;
    for start in 0..cells {
        if input[2 + start] == 0 || visited[start] {
            continue;
        }
        let (mut top, mut area) = (0usize, 0usize);
        visited[start] = true;
        stack[top] = start;
        top += 1;
        while top > 0 {
            top -= 1;
            let current = stack[top];
            area += 1;
            let row = current / columns;
            let column = current % columns;
            let mut visit = |neighbor: usize| {
                if !visited[neighbor] && input[2 + neighbor] != 0 {
                    visited[neighbor] = true;
                    stack[top] = neighbor;
                    top += 1;
                }
            };
            if row > 0 { visit(current - columns); }
            if column + 1 < columns { visit(current + 1); }
            if row + 1 < rows { visit(current + columns); }
            if column > 0 { visit(current - 1); }
        }
        maximum_area = maximum_area.max(area);
    }
    maximum_area as i64
}
