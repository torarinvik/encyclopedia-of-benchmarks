const MAX_CELLS: usize = 64;
const MAX_HITS: usize = 16;

fn find_root(parent: &mut [i32; 65], mut vertex: usize) -> usize {
    while parent[vertex] as usize != vertex {
        let next = parent[vertex] as usize;
        parent[vertex] = parent[next];
        vertex = parent[vertex] as usize;
    }
    vertex
}

fn unite(parent: &mut [i32; 65], size: &mut [i32; 65], left: usize, right: usize) {
    let mut a = find_root(parent, left);
    let mut b = find_root(parent, right);
    if a == b { return; }
    if size[a] < size[b] { std::mem::swap(&mut a, &mut b); }
    parent[b] = a as i32;
    size[a] += size[b];
}

fn build_dsu(grid: &[u8; MAX_CELLS], rows: usize, columns: usize,
             parent: &mut [i32; 65], size: &mut [i32; 65]) {
    let cells = rows * columns;
    for cell in 0..cells {
        parent[cell] = cell as i32;
        size[cell] = i32::from(grid[cell]);
    }
    parent[cells] = cells as i32;
    size[cells] = 0;
    for cell in 0..cells {
        if grid[cell] == 0 { continue; }
        let row = cell / columns;
        let column = cell % columns;
        if row == 0 { unite(parent, size, cell, cells); }
        if row > 0 && grid[cell - columns] != 0 { unite(parent, size, cell, cell - columns); }
        if column > 0 && grid[cell - 1] != 0 { unite(parent, size, cell, cell - 1); }
    }
}

unsafe fn put_i64_le(output: *mut u8, offset: usize, value: i32) {
    let bits = value as u64;
    for byte in 0..8 { *output.add(offset + byte) = (bits >> (8 * byte)) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn bricks_falling_when_hit_reverse_dsu(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 3 || length > 100 { return -1; }
    let row_value = *input;
    let column_value = *input.add(1);
    let hit_value = *input.add(2);
    if row_value < 1 || row_value > 8 || column_value < 1 || column_value > 8 ||
        hit_value < 0 || hit_value > MAX_HITS as i64 { return -1; }
    let rows = row_value as usize;
    let columns = column_value as usize;
    let cells = rows * columns;
    let hits = hit_value as usize;
    if hits > cells || length != 3 + cells + 2 * hits { return -1; }

    let mut grid = [0u8; MAX_CELLS];
    let mut parent = [0i32; 65];
    let mut component_size = [0i32; 65];
    for cell in 0..cells {
        let value = *input.add(3 + cell);
        if value != 0 && value != 1 { return -1; }
        grid[cell] = value as u8;
    }
    let hit_start = 3 + cells;
    for index in 0..hits {
        let row = *input.add(hit_start + 2 * index);
        let column = *input.add(hit_start + 2 * index + 1);
        if row < 0 || row >= row_value || column < 0 || column >= column_value { return -1; }
        for previous in 0..index {
            if *input.add(hit_start + 2 * previous) == row &&
                *input.add(hit_start + 2 * previous + 1) == column { return -1; }
        }
    }

    build_dsu(&grid, rows, columns, &mut parent, &mut component_size);
    let roof_root = find_root(&mut parent, cells);
    for cell in 0..cells {
        if grid[cell] != 0 && find_root(&mut parent, cell) != roof_root { return -1; }
    }

    let required = hits * 8;
    if capacity < required || (required != 0 && output.is_null()) { return -2; }
    if hits == 0 { return 0; }
    for index in 0..hits {
        let row = *input.add(hit_start + 2 * index) as usize;
        let column = *input.add(hit_start + 2 * index + 1) as usize;
        grid[row * columns + column] = 0;
    }
    build_dsu(&grid, rows, columns, &mut parent, &mut component_size);

    for reverse in 0..hits {
        let index = hits - 1 - reverse;
        let row = *input.add(hit_start + 2 * index) as usize;
        let column = *input.add(hit_start + 2 * index + 1) as usize;
        let cell = row * columns + column;
        if *input.add(3 + cell) == 0 { put_i64_le(output, index * 8, 0); continue; }
        let before_root = find_root(&mut parent, cells);
        let before = component_size[before_root];
        grid[cell] = 1;
        parent[cell] = cell as i32;
        component_size[cell] = 1;
        if row == 0 { unite(&mut parent, &mut component_size, cell, cells); }
        if row > 0 && grid[cell - columns] != 0 { unite(&mut parent, &mut component_size, cell, cell - columns); }
        if row + 1 < rows && grid[cell + columns] != 0 { unite(&mut parent, &mut component_size, cell, cell + columns); }
        if column > 0 && grid[cell - 1] != 0 { unite(&mut parent, &mut component_size, cell, cell - 1); }
        if column + 1 < columns && grid[cell + 1] != 0 { unite(&mut parent, &mut component_size, cell, cell + 1); }
        let after = component_size[find_root(&mut parent, cells)];
        let fallen = if after > before + 1 { after - before - 1 } else { 0 };
        put_i64_le(output, index * 8, fallen);
    }
    required as i64
}
