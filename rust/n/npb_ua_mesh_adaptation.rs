const DEPTH: i32 = 2;
const SIDE: i32 = 4;
const MAX_CELLS: usize = 64;
const INVALID_RESULT: f64 = -1.0e300;

#[derive(Clone, Copy, Default)]
struct Cell { level: i32, x: i32, y: i32, z: i32 }

fn cell_size(cell: Cell) -> i32 { 1 << (DEPTH - cell.level) }
fn overlaps_source(cell: Cell, source: [i32; 3], radius: i32) -> bool {
    let lower = [cell.x, cell.y, cell.z];
    let size = cell_size(cell);
    let mut squared = 0;
    for axis in 0..3 {
        let gap = if source[axis] < lower[axis] { lower[axis] - source[axis] }
                  else if source[axis] > lower[axis] + size { source[axis] - lower[axis] - size }
                  else { 0 };
        squared += gap * gap;
    }
    squared < radius * radius
}

fn neighboring(a: Cell, b: Cell) -> bool {
    let alo = [a.x, a.y, a.z];
    let blo = [b.x, b.y, b.z];
    let (asize, bsize) = (cell_size(a), cell_size(b));
    let mut touching = 0;
    for axis in 0..3 {
        let (ahi, bhi) = (alo[axis] + asize, blo[axis] + bsize);
        if ahi == blo[axis] || bhi == alo[axis] { touching += 1; }
        else if ahi <= blo[axis] || bhi <= alo[axis] { return false; }
    }
    touching == 1 || touching == 2
}

fn split_cell(cells: &mut [Cell; MAX_CELLS], count: &mut usize, index: usize) -> bool {
    let parent = cells[index];
    if parent.level >= DEPTH || *count + 7 > MAX_CELLS { return false; }
    let child_size = cell_size(parent) / 2;
    for i in (index + 1..*count).rev() { cells[i + 7] = cells[i]; }
    let mut slot = index;
    for bz in 0..2 { for by in 0..2 { for bx in 0..2 {
        cells[slot] = Cell { level: parent.level + 1, x: parent.x + bx * child_size,
            y: parent.y + by * child_size, z: parent.z + bz * child_size };
        slot += 1;
    }}}
    *count += 7;
    true
}

fn balanced(cells: &[Cell; MAX_CELLS], count: usize) -> bool {
    for i in 0..count { for j in i + 1..count {
        if neighboring(cells[i], cells[j]) && (cells[i].level - cells[j].level).abs() > 1 { return false; }
    }}
    true
}

fn balance_mesh(cells: &mut [Cell; MAX_CELLS], count: &mut usize) -> bool {
    loop {
        let mut coarse = None;
        'pairs: for i in 0..*count { for j in i + 1..*count {
            if neighboring(cells[i], cells[j]) && (cells[i].level - cells[j].level).abs() > 1 {
                coarse = Some(if cells[i].level < cells[j].level { i } else { j });
                break 'pairs;
            }
        }}
        match coarse {
            None => return true,
            Some(index) if split_cell(cells, count, index) => {},
            Some(_) => return false,
        }
    }
}

fn is_child(cell: Cell, level: i32, x: i32, y: i32, z: i32, size: i32) -> bool {
    cell.level == level && cell.x >= x && cell.x < x + size && cell.y >= y && cell.y < y + size && cell.z >= z && cell.z < z + size
}

fn coarsen_once(cells: &mut [Cell; MAX_CELLS], count: &mut usize, source: [i32; 3], radius: i32) -> bool {
    for seed in 0..*count {
        let child = cells[seed];
        if child.level == 0 { continue; }
        let parent_level = child.level - 1;
        let parent_size = 1 << (DEPTH - parent_level);
        let child_size = parent_size / 2;
        let px = child.x / parent_size * parent_size;
        let py = child.y / parent_size * parent_size;
        let pz = child.z / parent_size * parent_size;
        let parent = Cell { level: parent_level, x: px, y: py, z: pz };
        if overlaps_source(parent, source, radius) { continue; }
        let mut found = [-1isize; 8];
        for i in 0..*count { if is_child(cells[i], child.level, px, py, pz, parent_size) {
            let bx = ((cells[i].x - px) / child_size) as usize;
            let by = ((cells[i].y - py) / child_size) as usize;
            let bz = ((cells[i].z - pz) / child_size) as usize;
            found[bx + 2 * by + 4 * bz] = i as isize;
        }}
        if found.iter().any(|&index| index < 0) { continue; }
        let mut safe = true;
        for i in 0..*count {
            let sibling = found.contains(&(i as isize));
            if !sibling && neighboring(parent, cells[i]) && (parent_level - cells[i].level).abs() > 1 { safe = false; }
        }
        if !safe { continue; }
        let mut compact = [Cell::default(); MAX_CELLS];
        let mut compact_count = 0;
        let mut inserted = false;
        for i in 0..*count {
            if !found.contains(&(i as isize)) { compact[compact_count] = cells[i]; compact_count += 1; }
            else if !inserted { compact[compact_count] = parent; compact_count += 1; inserted = true; }
        }
        cells[..compact_count].copy_from_slice(&compact[..compact_count]);
        *count = compact_count;
        return true;
    }
    false
}

fn less_cell(a: Cell, b: Cell) -> bool {
    (a.level, a.z, a.y, a.x) < (b.level, b.z, b.y, b.x)
}

#[no_mangle]
pub unsafe extern "C" fn npb_ua_mesh_adaptation(input: *const i64, length: usize) -> f64 {
    if input.is_null() || length < 9 || length > 261 { return INVALID_RESULT; }
    let values = std::slice::from_raw_parts(input, length);
    if values[0] < 0 || values[0] > SIDE as i64 || values[1] < 0 || values[1] > SIDE as i64 ||
       values[2] < 0 || values[2] > SIDE as i64 || values[3] < 1 || values[3] > SIDE as i64 ||
       values[4] < 1 || values[4] > MAX_CELLS as i64 { return INVALID_RESULT; }
    let source = [values[0] as i32, values[1] as i32, values[2] as i32];
    let radius = values[3] as i32;
    let mut count = values[4] as usize;
    if length != 5 + 4 * count { return INVALID_RESULT; }
    let mut cells = [Cell::default(); MAX_CELLS];
    let mut covered = [false; MAX_CELLS];
    for i in 0..count {
        let raw = [values[5 + 4 * i], values[6 + 4 * i], values[7 + 4 * i], values[8 + 4 * i]];
        if raw[0] < 0 || raw[0] > DEPTH as i64 || raw[1] < 0 || raw[1] > SIDE as i64 ||
           raw[2] < 0 || raw[2] > SIDE as i64 || raw[3] < 0 || raw[3] > SIDE as i64 { return INVALID_RESULT; }
        let cell = Cell { level: raw[0] as i32, x: raw[1] as i32, y: raw[2] as i32, z: raw[3] as i32 };
        let size = cell_size(cell);
        if cell.x + size > SIDE || cell.y + size > SIDE || cell.z + size > SIDE ||
           cell.x % size != 0 || cell.y % size != 0 || cell.z % size != 0 { return INVALID_RESULT; }
        cells[i] = cell;
        for z in cell.z..cell.z + size { for y in cell.y..cell.y + size { for x in cell.x..cell.x + size {
            let q = (x + SIDE * (y + SIDE * z)) as usize;
            if covered[q] { return INVALID_RESULT; }
            covered[q] = true;
        }}}
    }
    if covered.iter().any(|&slot| !slot) || !balanced(&cells, count) { return INVALID_RESULT; }
    let mut i = 0;
    while i < count {
        if cells[i].level < DEPTH && overlaps_source(cells[i], source, radius) {
            if !split_cell(&mut cells, &mut count, i) { return INVALID_RESULT; }
        } else { i += 1; }
    }
    if !balance_mesh(&mut cells, &mut count) { return INVALID_RESULT; }
    while coarsen_once(&mut cells, &mut count, source, radius) {}
    if !balance_mesh(&mut cells, &mut count) { return INVALID_RESULT; }
    for i in 1..count {
        let key = cells[i];
        let mut j = i;
        while j > 0 && less_cell(key, cells[j - 1]) { cells[j] = cells[j - 1]; j -= 1; }
        cells[j] = key;
    }
    let mut checksum = 0.0;
    for i in 0..count {
        let cell = cells[i];
        let code = cell.level * 1000 + cell.x * 100 + cell.y * 10 + cell.z;
        checksum += (i + 1) as f64 * code as f64;
    }
    checksum
}
