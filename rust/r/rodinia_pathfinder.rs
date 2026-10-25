/// Bounded row-wise minimum-cost path through a grid.
#[no_mangle]
pub extern "C" fn rodinia_pathfinder(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 4 || length > 3 + 32 * 32 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    if values[0] < 1 || values[0] > 32 || values[1] < 1 || values[1] > 32 ||
        values[2] < 1 || values[2] > 4 { return -1; }
    let cols = values[0] as usize;
    let rows = values[1] as usize;
    let height = values[2] as usize;
    let cells = cols * rows;
    if length != 3 + cells || values[3..].iter().any(|&x| x < 0 || x > 9) { return -1; }
    let mut previous = [0i64; 32];
    let mut current = [0i64; 32];
    for col in 0..cols { previous[col] = values[3 + col]; }
    let mut first = 1;
    while first < rows {
        let steps = height.min(rows - first);
        for step in 0..steps {
            let row = first + step;
            for col in 0..cols {
                let mut best = previous[col];
                if col > 0 { best = best.min(previous[col - 1]); }
                if col + 1 < cols { best = best.min(previous[col + 1]); }
                current[col] = best + values[3 + row * cols + col];
            }
            for col in 0..cols { previous[col] = current[col]; }
        }
        first += height;
    }
    *previous[..cols].iter().min().unwrap()
}
