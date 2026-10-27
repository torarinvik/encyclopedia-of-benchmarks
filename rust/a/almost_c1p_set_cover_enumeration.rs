const MAX_ROWS: usize = 8;
const MAX_COLUMNS: usize = 10;
const MAX_OUTPUT_BYTES: usize = 80;

unsafe fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { *output.add(offset + byte) = (bits >> (8 * byte)) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn almost_c1p_set_cover_enumeration(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 4 || length > 21 { return -1; }
    let rows_raw = *input;
    let columns_raw = *input.add(1);
    if rows_raw < 1 || rows_raw > MAX_ROWS as i64 || columns_raw < 1 || columns_raw > MAX_COLUMNS as i64 ||
            length != 2 + rows_raw as usize + columns_raw as usize { return -1; }
    let rows = rows_raw as usize;
    let columns = columns_raw as usize;
    let mut weights = [0i64; MAX_COLUMNS];
    for column in 0..columns {
        let weight = *input.add(2 + column);
        if !(1..=20).contains(&weight) { return -1; }
        weights[column] = weight;
    }
    let valid_mask = (1u64 << columns) - 1;
    let mut row_masks = [0u64; MAX_ROWS];
    for row in 0..rows {
        let raw = *input.add(2 + columns + row);
        if raw < 0 || (raw as u64 & !valid_mask) != 0 { return -1; }
        row_masks[row] = raw as u64;
    }

    let state_count = 1usize << columns;
    let mut feasible = [false; 1 << MAX_COLUMNS];
    feasible[0] = true;
    for row in 0..rows {
        let cover_mask = row_masks[row];
        for selected in 0..state_count {
            if !feasible[selected] || (selected as u64 & cover_mask) != 0 { continue; }
            feasible[selected] = false;
            for column in 0..columns {
                let bit = 1u64 << column;
                if cover_mask & bit != 0 { feasible[selected | bit as usize] = true; }
            }
        }
    }

    let mut best: Option<(u64, i64)> = None;
    for selected in 0..state_count {
        if !feasible[selected] { continue; }
        let mut cost = 0i64;
        for column in 0..columns {
            if selected & (1usize << column) != 0 { cost += weights[column]; }
        }
        let mask = selected as u64;
        if best.is_none() || cost < best.unwrap().1 || (cost == best.unwrap().1 && mask < best.unwrap().0) {
            best = Some((mask, cost));
        }
    }
    let selected_count = best.map_or(0, |(mask, _)| mask.count_ones() as usize);
    let output_bytes = if best.is_some() { 8 * (selected_count + 2) } else { 8 };
    if output.is_null() || capacity < output_bytes { return -2; }
    let mut staged = [0u8; MAX_OUTPUT_BYTES];
    if let Some((mask, cost)) = best {
        store_i64_le(staged.as_mut_ptr(), 0, selected_count as i64);
        let mut cursor = 1usize;
        for column in 0..columns {
            if mask & (1u64 << column) != 0 {
                store_i64_le(staged.as_mut_ptr(), 8 * cursor, column as i64);
                cursor += 1;
            }
        }
        store_i64_le(staged.as_mut_ptr(), 8 * cursor, cost);
    } else {
        store_i64_le(staged.as_mut_ptr(), 0, -1);
    }
    for byte in 0..output_bytes { *output.add(byte) = staged[byte]; }
    output_bytes as i64
}
