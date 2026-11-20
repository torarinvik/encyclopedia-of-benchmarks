/// Zhang-Suen binary image thinning with simultaneous phase deletions.
const MAX_ROWS: i64 = 32;
const MAX_COLUMNS: i64 = 32;
const MAX_CELLS: usize = 1024;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 1027;

fn thin_phase(image: &mut [u8; MAX_CELLS], marked: &mut [u8; MAX_CELLS],
    rows: usize, columns: usize, second_phase: bool) -> bool {
    let cells = rows * columns;
    marked[..cells].fill(0);
    let mut changed = false;
    for row in 1..rows.saturating_sub(1) {
        for column in 1..columns.saturating_sub(1) {
            let index = row * columns + column;
            if image[index] == 0 { continue; }
            let p2 = image[index - columns];
            let p3 = image[index - columns + 1];
            let p4 = image[index + 1];
            let p5 = image[index + columns + 1];
            let p6 = image[index + columns];
            let p7 = image[index + columns - 1];
            let p8 = image[index - 1];
            let p9 = image[index - columns - 1];
            let ring = [p2, p3, p4, p5, p6, p7, p8, p9, p2];
            let mut black_neighbors: u8 = 0;
            let mut transitions = 0;
            for neighbor in 0..8 {
                black_neighbors += ring[neighbor];
                if ring[neighbor] == 0 && ring[neighbor + 1] == 1 { transitions += 1; }
            }
            if !(2..=6).contains(&black_neighbors) || transitions != 1 { continue; }
            let blocked = if second_phase {
                (p2 != 0 && p4 != 0 && p8 != 0) || (p2 != 0 && p6 != 0 && p8 != 0)
            } else {
                (p2 != 0 && p4 != 0 && p6 != 0) || (p4 != 0 && p6 != 0 && p8 != 0)
            };
            if blocked { continue; }
            marked[index] = 1;
            changed = true;
        }
    }
    if changed {
        for index in 0..cells {
            if marked[index] != 0 { image[index] = 0; }
        }
    }
    changed
}

#[no_mangle]
pub unsafe extern "C" fn zhang_suen_thinning(input: *const i64, length: usize,
    output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || length < 3 || length > MAX_PARSEABLE_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let rows_value = values[0];
    let columns_value = values[1];
    if !(1..=MAX_ROWS).contains(&rows_value) || !(1..=MAX_COLUMNS).contains(&columns_value) {
        return -1;
    }
    let rows = rows_value as usize;
    let columns = columns_value as usize;
    let cells = rows * columns;
    if length != 2 + cells || values[2..].iter().any(|&pixel| pixel != 0 && pixel != 1) {
        return -1;
    }
    if output.is_null() || output_capacity < cells { return -2; }

    let mut image = [0u8; MAX_CELLS];
    let mut marked = [0u8; MAX_CELLS];
    image[..cells].copy_from_slice(&values[2..]);
    loop {
        let first_changed = thin_phase(&mut image, &mut marked, rows, columns, false);
        let second_changed = thin_phase(&mut image, &mut marked, rows, columns, true);
        if !first_changed && !second_changed { break; }
    }
    std::ptr::copy_nonoverlapping(image.as_ptr(), output, cells);
    cells as i64
}
