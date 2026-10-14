const MAX_ROWS: i64 = 30;
const HASH_MOD: i64 = 1_000_000_007;

#[no_mangle]
pub unsafe extern "C" fn pascal_triangle_benchmark(values: *const i64, length: usize) -> i64 {
    if length != 1 { return -1; }
    let row_count_value = *values;
    if row_count_value < 0 || row_count_value > MAX_ROWS { return -1; }
    let row_count = row_count_value as usize;
    let mut row = [0_i64; MAX_ROWS as usize];
    row[0] = 1;
    let mut hash = 0_i64;
    for row_index in 0..row_count {
        let mut column = row_index;
        while column > 0 {
            row[column] += row[column - 1];
            column -= 1;
        }
        for column in 0..=row_index {
            hash = (hash * 31 + row[column] % HASH_MOD) % HASH_MOD;
        }
    }
    hash
}
