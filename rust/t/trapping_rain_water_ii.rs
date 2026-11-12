const MAX_ROWS: usize = 8;
const MAX_COLS: usize = 8;
const MAX_CELLS: usize = 64;
const MAX_INPUT: usize = 66;

#[derive(Clone, Copy, Default)]
struct Entry { level: i64, cell: usize }

fn less(a: Entry, b: Entry) -> bool { a.level < b.level || (a.level == b.level && a.cell < b.cell) }
fn push(heap: &mut [Entry; MAX_CELLS], size: &mut usize, item: Entry) {
    let mut position = *size;
    *size += 1;
    while position > 0 {
        let parent = (position - 1) / 2;
        if !less(item, heap[parent]) { break; }
        heap[position] = heap[parent];
        position = parent;
    }
    heap[position] = item;
}
fn pop(heap: &mut [Entry; MAX_CELLS], size: &mut usize) -> Entry {
    let minimum = heap[0];
    *size -= 1;
    if *size > 0 {
        let last = heap[*size];
        let mut position = 0;
        while 2 * position + 1 < *size {
            let mut child = 2 * position + 1;
            if child + 1 < *size && less(heap[child + 1], heap[child]) { child += 1; }
            if !less(heap[child], last) { break; }
            heap[position] = heap[child];
            position = child;
        }
        heap[position] = last;
    }
    minimum
}

fn solve(input: &[i64]) -> i64 {
    if input.len() < 2 || input.len() > MAX_INPUT { return -1; }
    if !(1..=MAX_ROWS as i64).contains(&input[0]) || !(1..=MAX_COLS as i64).contains(&input[1]) { return -1; }
    let rows = input[0] as usize;
    let cols = input[1] as usize;
    if input.len() != 2 + rows * cols { return -1; }
    let mut heights = [0i64; MAX_CELLS];
    for cell in 0..rows * cols {
        let height = input[2 + cell];
        if !(0..=1000).contains(&height) { return -1; }
        heights[cell] = height;
    }

    let mut visited = [false; MAX_CELLS];
    let mut heap = [Entry::default(); MAX_CELLS];
    let mut heap_size = 0;
    for row in 0..rows {
        for col in 0..cols {
            if row == 0 || row + 1 == rows || col == 0 || col + 1 == cols {
                let cell = row * cols + col;
                if !visited[cell] {
                    visited[cell] = true;
                    push(&mut heap, &mut heap_size, Entry { level: heights[cell], cell });
                }
            }
        }
    }

    let dr = [-1isize, 1, 0, 0];
    let dc = [0isize, 0, -1, 1];
    let mut retained = 0i64;
    while heap_size > 0 {
        let current = pop(&mut heap, &mut heap_size);
        let row = current.cell / cols;
        let col = current.cell % cols;
        for direction in 0..4 {
            let nr = row as isize + dr[direction];
            let nc = col as isize + dc[direction];
            if nr < 0 || nr >= rows as isize || nc < 0 || nc >= cols as isize { continue; }
            let neighbor = nr as usize * cols + nc as usize;
            if visited[neighbor] { continue; }
            visited[neighbor] = true;
            let height = heights[neighbor];
            if height < current.level { retained += current.level - height; }
            push(&mut heap, &mut heap_size, Entry { level: height.max(current.level), cell: neighbor });
        }
    }
    retained
}

#[no_mangle]
pub unsafe extern "C" fn trapping_rain_water_ii(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT { return -1; }
    solve(std::slice::from_raw_parts(input, length))
}
