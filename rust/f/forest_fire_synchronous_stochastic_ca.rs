const MAX_INPUT: usize = 1095;
const MAX_CELLS: usize = 64;

fn put_i64(output: &mut [u8], word: usize, value: i64) {
    let bytes = value.to_le_bytes();
    output[word * 8..word * 8 + 8].copy_from_slice(&bytes);
}

#[no_mangle]
pub unsafe extern "C" fn forest_fire_synchronous_stochastic_ca(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || !(6..=MAX_INPUT).contains(&length) { return -1; }
    let data = std::slice::from_raw_parts(input, length);
    if !(1..=8).contains(&data[0]) || !(1..=8).contains(&data[1]) ||
        !(0..=8).contains(&data[2]) || data[3] != 10_000 ||
        !(0..=10_000).contains(&data[4]) || !(0..=10_000).contains(&data[5]) { return -1; }
    let rows = data[0] as usize;
    let cols = data[1] as usize;
    let steps = data[2] as usize;
    let cells = rows * cols;
    if length != 6 + cells + 2 * steps * cells { return -1; }
    if data[6..6 + cells].iter().any(|&state| !(0..=2).contains(&state)) ||
        data[6 + cells..].iter().any(|&draw| !(0..10_000).contains(&draw)) { return -1; }
    for row in 0..rows {
        for col in 0..cols {
            if (row == 0 || row + 1 == rows || col == 0 || col + 1 == cols) && data[6 + row * cols + col] != 0 { return -1; }
        }
    }
    let bytes = (1 + 3 * steps + cells) * 8;
    if output.is_null() || capacity < bytes { return -2; }
    let out = std::slice::from_raw_parts_mut(output, bytes);
    let tape = 6 + cells;
    let mut current = [0u8; MAX_CELLS];
    let mut next = [0u8; MAX_CELLS];
    for i in 0..cells { current[i] = data[6 + i] as u8; }
    put_i64(out, 0, steps as i64);
    for tick in 0..steps {
        for row in 0..rows {
            for col in 0..cols {
                let site = row * cols + col;
                if row == 0 || row + 1 == rows || col == 0 || col + 1 == cols { next[site] = 0; continue; }
                match current[site] {
                    2 => next[site] = 0,
                    0 => next[site] = if data[tape + tick * cells + site] < data[4] { 1 } else { 0 },
                    _ => {
                        let mut adjacent = false;
                        for rr in row.saturating_sub(1)..=(row + 1).min(rows - 1) {
                            for cc in col.saturating_sub(1)..=(col + 1).min(cols - 1) {
                                if (rr != row || cc != col) && current[rr * cols + cc] == 2 { adjacent = true; }
                            }
                        }
                        let strike = data[tape + steps * cells + tick * cells + site];
                        next[site] = if adjacent || strike < data[5] { 2 } else { 1 };
                    }
                }
            }
        }
        let mut totals = [0i64; 3];
        for &state in &next[..cells] { totals[state as usize] += 1; }
        for state in 0..3 { put_i64(out, 1 + 3 * tick + state, totals[state]); }
        current[..cells].copy_from_slice(&next[..cells]);
    }
    for i in 0..cells { put_i64(out, 1 + 3 * steps + i, current[i] as i64); }
    bytes as i64
}
