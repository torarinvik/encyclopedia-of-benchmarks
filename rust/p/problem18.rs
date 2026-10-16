const MAX_ROWS: usize = 15;
const MAX_VALUES: usize = MAX_ROWS * (MAX_ROWS + 1) / 2;
const VALUE_LIMIT: i64 = 1_000_000;

/// Return the maximum sum along a top-to-bottom adjacent path in a triangle.
#[no_mangle]
pub unsafe extern "C" fn problem18(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_VALUES + 1 {
        return -1;
    }
    let rows = *input;
    if !(1..=MAX_ROWS as i64).contains(&rows) || length != (rows * (rows + 1) / 2) as usize + 1 {
        return -1;
    }
    let value_count = length - 1;
    let mut best = [0i64; MAX_VALUES];
    for index in 0..value_count {
        let value = *input.add(index + 1);
        if !(0..=VALUE_LIMIT).contains(&value) {
            return -1;
        }
        best[index] = value;
    }
    let mut row = rows - 1;
    while row > 0 {
        let parent_start = ((row - 1) * row / 2) as usize;
        let child_start = (row * (row + 1) / 2) as usize;
        for column in 0..row as usize {
            let parent = parent_start + column;
            let child = child_start + column;
            best[parent] += best[child].max(best[child + 1]);
        }
        row -= 1;
    }
    best[0]
}
