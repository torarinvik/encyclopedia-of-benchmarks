const MAX_ROWS: usize = 8;
const MAX_COLUMNS: usize = 8;
const MAX_INPUT: usize = 19;
const MAX_OUTPUT: usize = 272;

unsafe fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { *output.add(offset + byte) = (bits >> (8 * byte)) as u8; }
}

fn column_coverage(masks: &[u64; MAX_ROWS], active_rows: &[bool; MAX_ROWS], rows: usize, column: usize) -> u64 {
    let mut coverage = 0u64;
    for row in 0..rows {
        if active_rows[row] && masks[row] & (1u64 << column) != 0 { coverage |= 1u64 << row; }
    }
    coverage
}

#[no_mangle]
pub unsafe extern "C" fn set_cover_domination_reduction(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 4 || length > MAX_INPUT { return -1; }
    let rows_raw = *input;
    let columns_raw = *input.add(1);
    if !(1..=MAX_ROWS as i64).contains(&rows_raw) || !(1..=MAX_COLUMNS as i64).contains(&columns_raw)
        || length != 2 + rows_raw as usize + columns_raw as usize { return -1; }
    let rows = rows_raw as usize;
    let columns = columns_raw as usize;
    let mut weights = [0i64; MAX_COLUMNS];
    let mut active_columns = [false; MAX_COLUMNS];
    for column in 0..columns {
        let weight = *input.add(2 + column);
        if !(1..=20).contains(&weight) { return -1; }
        weights[column] = weight;
        active_columns[column] = true;
    }
    let valid_columns = (1u64 << columns) - 1;
    let mut masks = [0u64; MAX_ROWS];
    let mut active_rows = [false; MAX_ROWS];
    for row in 0..rows {
        let raw = *input.add(2 + columns + row);
        if raw < 0 || raw as u64 & !valid_columns != 0 { return -1; }
        masks[row] = raw as u64;
        active_rows[row] = true;
    }

    loop {
        let mut changed = false;
        for keep in 0..rows {
            if !active_rows[keep] { continue; }
            for drop in 0..rows {
                if !active_rows[drop] || keep == drop { continue; }
                if masks[keep] & !masks[drop] == 0 && (masks[keep] != masks[drop] || keep < drop) {
                    active_rows[drop] = false;
                    changed = true;
                    break;
                }
            }
            if changed { break; }
        }
        if changed { continue; }

        for drop in 0..columns {
            if !active_columns[drop] { continue; }
            let drop_cover = column_coverage(&masks, &active_rows, rows, drop);
            for keep in 0..columns {
                if !active_columns[keep] || keep == drop { continue; }
                let keep_cover = column_coverage(&masks, &active_rows, rows, keep);
                if drop_cover & !keep_cover == 0 && weights[drop] >= weights[keep]
                    && (drop_cover != keep_cover || weights[drop] != weights[keep] || keep < drop) {
                    active_columns[drop] = false;
                    for row in 0..rows { masks[row] &= !(1u64 << drop); }
                    changed = true;
                    break;
                }
            }
            if changed { break; }
        }
        if changed { continue; }

        for drop in 0..columns {
            if !active_columns[drop] { continue; }
            let drop_cover = column_coverage(&masks, &active_rows, rows, drop);
            for keep in 0..columns {
                if !active_columns[keep] || keep == drop { continue; }
                let keep_cover = column_coverage(&masks, &active_rows, rows, keep);
                let exclusive_rows = drop_cover & !keep_cover;
                if drop_cover & keep_cover == 0 || exclusive_rows == 0 { continue; }
                let mut replacement_columns = 0u64;
                let mut feasible = true;
                for row in 0..rows {
                    if exclusive_rows & (1u64 << row) == 0 { continue; }
                    let mut minimum_column: Option<usize> = None;
                    for candidate in 0..columns {
                        if !active_columns[candidate] || masks[row] & (1u64 << candidate) == 0 { continue; }
                        if minimum_column.is_none_or(|old| (weights[candidate], candidate) < (weights[old], old)) {
                            minimum_column = Some(candidate);
                        }
                    }
                    if let Some(candidate) = minimum_column { replacement_columns |= 1u64 << candidate; }
                    else { feasible = false; break; }
                }
                let mut replacement_cost = weights[keep];
                for candidate in 0..columns {
                    if replacement_columns & (1u64 << candidate) != 0 { replacement_cost += weights[candidate]; }
                }
                if feasible && weights[drop] >= replacement_cost {
                    active_columns[drop] = false;
                    for row in 0..rows { masks[row] &= !(1u64 << drop); }
                    changed = true;
                    break;
                }
            }
            if changed { break; }
        }
        if !changed { break; }
    }

    let row_ids: Vec<usize> = (0..rows).filter(|&row| active_rows[row]).collect();
    let column_ids: Vec<usize> = (0..columns).filter(|&column| active_columns[column]).collect();
    let mut reduced_masks = [0u64; MAX_ROWS];
    for (i, &row) in row_ids.iter().enumerate() {
        for (j, &column) in column_ids.iter().enumerate() {
            if masks[row] & (1u64 << column) != 0 { reduced_masks[i] |= 1u64 << j; }
        }
    }
    let words = 2 + 2 * row_ids.len() + 2 * column_ids.len();
    let bytes = 8 * words;
    let mut staged = [0u8; MAX_OUTPUT];
    let mut cursor = 0;
    store_i64_le(staged.as_mut_ptr(), 8 * cursor, row_ids.len() as i64); cursor += 1;
    store_i64_le(staged.as_mut_ptr(), 8 * cursor, column_ids.len() as i64); cursor += 1;
    for &row in &row_ids { store_i64_le(staged.as_mut_ptr(), 8 * cursor, row as i64); cursor += 1; }
    for &column in &column_ids { store_i64_le(staged.as_mut_ptr(), 8 * cursor, column as i64); cursor += 1; }
    for &column in &column_ids { store_i64_le(staged.as_mut_ptr(), 8 * cursor, weights[column]); cursor += 1; }
    for i in 0..row_ids.len() { store_i64_le(staged.as_mut_ptr(), 8 * cursor, reduced_masks[i] as i64); cursor += 1; }
    if output.is_null() || capacity < bytes { return -2; }
    for byte in 0..bytes { *output.add(byte) = staged[byte]; }
    bytes as i64
}
