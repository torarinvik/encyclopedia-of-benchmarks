const MAX_DIM: usize = 5;
const MAX_PAT_DIM: usize = 4;
const MAX_INPUT: usize = 196;
const MAX_MATCHES: usize = 125;

unsafe fn put(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { *output.add(offset + byte) = (bits >> (8 * byte)) as u8; }
}

fn same_rows(plane: &[i64; MAX_PAT_DIM * MAX_PAT_DIM], left: usize,
             right: usize, width: usize) -> bool {
    for column in 0..width {
        if plane[left * width + column] != plane[right * width + column] { return false; }
    }
    true
}

#[no_mangle]
pub unsafe extern "C" fn three_dimensional_bird_baker_matching(
    input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 7 || length > MAX_INPUT { return -1; }
    let r0 = *input;
    let c0 = *input.add(1);
    let d0 = *input.add(2);
    let pr0 = *input.add(3);
    let pc0 = *input.add(4);
    let pd0 = *input.add(5);
    if !(1..=5).contains(&r0) || !(1..=5).contains(&c0) || !(1..=5).contains(&d0)
        || !(1..=4).contains(&pr0) || !(1..=4).contains(&pc0) || !(1..=4).contains(&pd0)
        || pr0 > r0 || pc0 > c0 || pd0 > d0 { return -1; }
    let rows = r0 as usize;
    let columns = c0 as usize;
    let depths = d0 as usize;
    let p_rows = pr0 as usize;
    let p_columns = pc0 as usize;
    let p_depths = pd0 as usize;
    let text_size = rows * columns * depths;
    let pattern_size = p_rows * p_columns * p_depths;
    if length != 6 + text_size + pattern_size { return -1; }
    let mut text = [0i64; MAX_DIM * MAX_DIM * MAX_DIM];
    let mut pattern = [0i64; MAX_PAT_DIM * MAX_PAT_DIM * MAX_PAT_DIM];
    for i in 0..text_size {
        text[i] = *input.add(6 + i);
        if !(0..=3).contains(&text[i]) { return -1; }
    }
    for i in 0..pattern_size {
        pattern[i] = *input.add(6 + text_size + i);
        if !(0..=3).contains(&pattern[i]) { return -1; }
    }

    let mut plane_ids = [0usize; MAX_PAT_DIM];
    let mut unique_planes = [[0i64; MAX_PAT_DIM * MAX_PAT_DIM]; MAX_PAT_DIM];
    let plane_area = p_rows * p_columns;
    let mut unique_count = 0usize;
    for pz in 0..p_depths {
        let mut found = unique_count;
        for candidate in 0..unique_count {
            let mut equal = true;
            for i in 0..plane_area {
                if unique_planes[candidate][i] != pattern[pz * plane_area + i] { equal = false; }
            }
            if equal { found = candidate; break; }
        }
        if found == unique_count {
            for i in 0..plane_area { unique_planes[unique_count][i] = pattern[pz * plane_area + i]; }
            unique_count += 1;
        }
        plane_ids[pz] = found;
    }

    let row_starts = rows - p_rows + 1;
    let column_starts = columns - p_columns + 1;
    let mut labels = [[[-1i8; MAX_DIM]; MAX_DIM]; MAX_DIM];
    for z in 0..depths {
        for unique in 0..unique_count {
            let mut marks = [[[false; MAX_PAT_DIM]; MAX_DIM]; MAX_DIM];
            let mut prefix = [0usize; MAX_PAT_DIM];
            for i in 1..p_rows {
                let mut matched = prefix[i - 1];
                while matched > 0 && !same_rows(&unique_planes[unique], i, matched, p_columns) {
                    matched = prefix[matched - 1];
                }
                if same_rows(&unique_planes[unique], i, matched, p_columns) { matched += 1; }
                prefix[i] = matched;
            }
            for row in 0..rows {
                for col in 0..column_starts {
                    for p_row in 0..p_rows {
                        let mut equal = true;
                        for p_col in 0..p_columns {
                            if text[(z * rows + row) * columns + col + p_col]
                                != unique_planes[unique][p_row * p_columns + p_col] { equal = false; }
                        }
                        marks[row][col][p_row] = equal;
                    }
                }
            }
            for col in 0..column_starts {
                let mut matched = 0usize;
                for row in 0..rows {
                    while matched > 0 && !marks[row][col][matched] { matched = prefix[matched - 1]; }
                    if marks[row][col][matched] { matched += 1; }
                    if matched == p_rows {
                        labels[z][row + 1 - p_rows][col] = unique as i8;
                        matched = prefix[matched - 1];
                    }
                }
            }
        }
    }

    let mut depth_prefix = [0usize; MAX_PAT_DIM];
    for i in 1..p_depths {
        let mut matched = depth_prefix[i - 1];
        while matched > 0 && plane_ids[i] != plane_ids[matched] { matched = depth_prefix[matched - 1]; }
        if plane_ids[i] == plane_ids[matched] { matched += 1; }
        depth_prefix[i] = matched;
    }
    let mut matches = [[0i64; 3]; MAX_MATCHES];
    let mut count = 0usize;
    for row in 0..row_starts {
        for col in 0..column_starts {
            let mut matched = 0usize;
            for z in 0..depths {
                let token = labels[z][row][col];
                while matched > 0 && token != plane_ids[matched] as i8 { matched = depth_prefix[matched - 1]; }
                if token == plane_ids[matched] as i8 { matched += 1; }
                if matched == p_depths {
                    matches[count] = [row as i64, col as i64, (z + 1 - p_depths) as i64];
                    count += 1;
                    matched = depth_prefix[matched - 1];
                }
            }
        }
    }
    let bytes = 8 * (1 + 3 * count);
    if output.is_null() || capacity < bytes { return -2; }
    put(output, 0, count as i64);
    for i in 0..count {
        for axis in 0..3 { put(output, 8 * (1 + 3 * i + axis), matches[i][axis]); }
    }
    bytes as i64
}
