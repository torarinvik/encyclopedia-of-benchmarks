/// Run-length-native LCS by run-pair blocks and boundary propagation.
#[no_mangle]
pub extern "C" fn rle_lcs_block_dp(packed: *const i64, length: usize) -> i64 {
    if packed.is_null() || length < 4 || length > 18 { return -1; }
    let packed = unsafe { std::slice::from_raw_parts(packed, length) };
    let left_count = packed[0];
    if !(1..=4).contains(&left_count) { return -1; }
    let left_count = left_count as usize;
    let right_count_index = 1 + 2 * left_count;
    if right_count_index >= length { return -1; }
    let right_count = packed[right_count_index];
    if !(1..=4).contains(&right_count) || length != right_count_index + 1 + 2 * right_count as usize { return -1; }
    let right_count = right_count as usize;
    let mut left_symbol = [0i64; 4];
    let mut left_size = [0usize; 4];
    let mut right_symbol = [0i64; 4];
    let mut right_size = [0usize; 4];
    let mut left_total = 0usize;
    let mut right_total = 0usize;
    for run in 0..left_count {
        let symbol = packed[1 + 2 * run];
        let size = packed[2 + 2 * run];
        if !(0..=3).contains(&symbol) || !(1..=8).contains(&size) { return -1; }
        left_total += size as usize;
        if left_total > 16 { return -1; }
        left_symbol[run] = symbol;
        left_size[run] = size as usize;
    }
    for run in 0..right_count {
        let symbol = packed[right_count_index + 1 + 2 * run];
        let size = packed[right_count_index + 2 + 2 * run];
        if !(0..=3).contains(&symbol) || !(1..=8).contains(&size) { return -1; }
        right_total += size as usize;
        if right_total > 16 { return -1; }
        right_symbol[run] = symbol;
        right_size[run] = size as usize;
    }
    let mut bottom = [[0i64; 9]; 4];
    let mut next_bottom = [[0i64; 9]; 4];
    for i in 0..left_count {
        let mut left_boundary = [0i64; 9];
        for j in 0..right_count {
            let rows = left_size[i];
            let columns = right_size[j];
            let mut previous = [0i64; 9];
            let mut current = [0i64; 9];
            let mut right_boundary = [0i64; 9];
            for column in 0..=columns { previous[column] = bottom[j][column]; }
            right_boundary[0] = previous[columns];
            for row in 1..=rows {
                current[0] = left_boundary[row];
                for column in 1..=columns {
                    current[column] = if left_symbol[i] == right_symbol[j] {
                        previous[column - 1] + 1
                    } else {
                        previous[column].max(current[column - 1])
                    };
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
    }
    bottom[right_count - 1][right_size[right_count - 1]]
}
