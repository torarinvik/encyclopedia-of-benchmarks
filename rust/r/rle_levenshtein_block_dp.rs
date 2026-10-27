/// Run-length-native unit-cost edit distance by run-pair blocks.
#[no_mangle]
pub unsafe extern "C" fn rle_levenshtein_block_dp(packed: *const i64, length: usize) -> i64 {
    if packed.is_null() || length < 4 || length > 18 { return -1; }
    let input = std::slice::from_raw_parts(packed, length);
    if !(1..=4).contains(&input[0]) { return -1; }
    let left_count = input[0] as usize;
    let right_index = 1 + 2 * left_count;
    if right_index >= length || !(1..=4).contains(&input[right_index]) { return -1; }
    let right_count = input[right_index] as usize;
    if length != right_index + 1 + 2 * right_count { return -1; }
    let mut left_symbol = [0i64; 4]; let mut left_size = [0usize; 4];
    let mut right_symbol = [0i64; 4]; let mut right_size = [0usize; 4];
    let mut left_total = 0usize; let mut right_total = 0usize;
    for run in 0..left_count {
        let symbol = input[1 + 2 * run]; let size = input[2 + 2 * run];
        if !(0..=3).contains(&symbol) || !(1..=8).contains(&size) { return -1; }
        left_total += size as usize; if left_total > 16 { return -1; }
        left_symbol[run] = symbol; left_size[run] = size as usize;
    }
    for run in 0..right_count {
        let symbol = input[right_index + 1 + 2 * run];
        let size = input[right_index + 2 + 2 * run];
        if !(0..=3).contains(&symbol) || !(1..=8).contains(&size) { return -1; }
        right_total += size as usize; if right_total > 16 { return -1; }
        right_symbol[run] = symbol; right_size[run] = size as usize;
    }
    let mut bottom = [[0i64; 9]; 4];
    let mut next_bottom = [[0i64; 9]; 4];
    let mut right_prefix = 0usize;
    for j in 0..right_count {
        for column in 0..=right_size[j] { bottom[j][column] = (right_prefix + column) as i64; }
        right_prefix += right_size[j];
    }
    let mut left_prefix = 0usize;
    for i in 0..left_count {
        let rows = left_size[i];
        let mut left_boundary = [0i64; 9];
        for row in 0..=rows { left_boundary[row] = (left_prefix + row) as i64; }
        for j in 0..right_count {
            let columns = right_size[j];
            let mut previous = [0i64; 9]; let mut current = [0i64; 9];
            let mut right_boundary = [0i64; 9];
            for column in 0..=columns { previous[column] = bottom[j][column]; }
            right_boundary[0] = previous[columns];
            let substitution = if left_symbol[i] == right_symbol[j] { 0 } else { 1 };
            for row in 1..=rows {
                current[0] = left_boundary[row];
                for column in 1..=columns {
                    current[column] = (previous[column] + 1)
                        .min(current[column - 1] + 1)
                        .min(previous[column - 1] + substitution);
                }
                right_boundary[row] = current[columns];
                for column in 0..=columns { previous[column] = current[column]; }
            }
            for column in 0..=columns { next_bottom[j][column] = previous[column]; }
            for row in 0..=rows { left_boundary[row] = right_boundary[row]; }
        }
        for j in 0..right_count {
            for column in 0..=right_size[j] { bottom[j][column] = next_bottom[j][column]; }
        }
        left_prefix += rows;
    }
    bottom[right_count - 1][right_size[right_count - 1]]
}
