#[no_mangle]
pub unsafe extern "C" fn sparse_supernodal_cholesky(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || !(2..=56).contains(&length) { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if !(1..=8).contains(&values[0]) || values[1] < 1 || values[1] > values[0] { return -1; }
    let n = values[0] as usize;
    let count = values[1] as usize;
    let triangle = n * (n + 1) / 2;
    if length != 3 + count + n + triangle { return -1; }
    let raw_boundaries = &values[2..3 + count];
    if raw_boundaries[0] != 0 || raw_boundaries[count] != n as i64
        || raw_boundaries.windows(2).any(|pair| pair[0] >= pair[1]) { return -1; }
    let mut boundaries = [0usize; 9];
    for (i, &value) in raw_boundaries.iter().enumerate() {
        if !(0..=n as i64).contains(&value) { return -1; }
        boundaries[i] = value as usize;
    }
    let mut masks = [0usize; 8];
    for row in 0..n {
        let mask = values[3 + count + row];
        if mask < 0 || mask >= (1i64 << (row + 1)) || mask & (1i64 << row) == 0 { return -1; }
        masks[row] = mask as usize;
    }
    for col in 0..n {
        for row in col + 1..n {
            if masks[row] & (1 << col) == 0 { continue; }
            for lower in row + 1..n {
                if masks[lower] & (1 << col) != 0 && masks[lower] & (1 << row) == 0 { return -1; }
            }
        }
    }
    for block in 0..count {
        let (start, end) = (boundaries[block], boundaries[block + 1]);
        for row in start..end {
            for col in start..row { if masks[row] & (1 << col) == 0 { return -1; } }
        }
        let block_mask = ((1usize << end) - 1) ^ ((1usize << start) - 1);
        for &mask in &masks[end..n] {
            let selected = mask & block_mask;
            if selected != 0 && selected != block_mask { return -1; }
        }
    }
    let mut slots = [[usize::MAX; 8]; 8];
    let mut sparse = [0.0f64; 36];
    let mut used = 0;
    let mut cursor = 3 + count + n;
    for row in 0..n {
        for col in 0..=row {
            let value = values[cursor]; cursor += 1;
            if !(-1_000_000..=1_000_000).contains(&value) { return -1; }
            if masks[row] & (1 << col) == 0 {
                if value != 0 { return -1; }
            } else {
                slots[row][col] = used;
                sparse[used] = value as f64 / 1000.0;
                used += 1;
            }
        }
    }
    for block in 0..count {
        let (start, end) = (boundaries[block], boundaries[block + 1]);
        for col in start..end {
            let pivot = sparse[slots[col][col]];
            if !pivot.is_finite() || pivot <= 0.0 { return -1; }
            sparse[slots[col][col]] = pivot.sqrt();
            for row in col + 1..end { sparse[slots[row][col]] /= sparse[slots[col][col]]; }
            for row in col + 1..end {
                for target in col + 1..=row {
                    sparse[slots[row][target]] -= sparse[slots[row][col]] * sparse[slots[target][col]];
                }
            }
        }
        for row in end..n {
            if masks[row] & (1 << start) == 0 { continue; }
            for col in start..end {
                let mut value = sparse[slots[row][col]];
                for k in start..col { value -= sparse[slots[row][k]] * sparse[slots[col][k]]; }
                sparse[slots[row][col]] = value / sparse[slots[col][col]];
            }
        }
        for row in end..n {
            if masks[row] & (1 << start) == 0 { continue; }
            for target in end..=row {
                if masks[target] & (1 << start) == 0 { continue; }
                for k in start..end {
                    sparse[slots[row][target]] -= sparse[slots[row][k]] * sparse[slots[target][k]];
                }
            }
        }
    }
    let bytes = triangle * 8;
    if output.is_null() || capacity < bytes { return -2; }
    let destination = std::slice::from_raw_parts_mut(output, bytes);
    let mut offset = 0;
    for row in 0..n {
        for col in 0..=row {
            let value = if slots[row][col] == usize::MAX { 0.0 } else { sparse[slots[row][col]] };
            destination[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
            offset += 8;
        }
    }
    bytes as i64
}
