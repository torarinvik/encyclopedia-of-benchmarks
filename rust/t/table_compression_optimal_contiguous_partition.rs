const ROWS: usize = 8;
const COLS: usize = 8;
const INPUT: usize = 66;
const OUTPUT: usize = 24;

fn interval_cost(table: &[i64], rows: usize, cols: usize, begin: usize, end: usize) -> i64 {
    let mut runs = 0;
    let mut previous = None;
    for row in 0..rows {
        for col in begin..end {
            let value = table[row * cols + col];
            if previous != Some(value) { runs += 1; }
            previous = Some(value);
        }
    }
    2 * runs
}

fn put(out: &mut [u8], at: usize, value: i64) {
    out[at..at + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn table_compression_optimal_contiguous_partition(
    values: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if values.is_null() || length < 3 || length > INPUT { return -1; }
    let rows0 = *values;
    let cols0 = *values.add(1);
    if rows0 < 1 || rows0 > ROWS as i64 || cols0 < 1 || cols0 > COLS as i64 { return -1; }
    let rows = rows0 as usize;
    let cols = cols0 as usize;
    if length != 2 + rows * cols { return -1; }
    let table = std::slice::from_raw_parts(values.add(2), rows * cols);
    if table.iter().any(|&value| !(0..=15).contains(&value)) { return -1; }

    let mut cost = [0i64; COLS + 1];
    let mut previous = [0usize; COLS + 1];
    for end in 1..=cols {
        cost[end] = i64::MAX;
        for start in 0..end {
            let candidate = cost[start] + interval_cost(table, rows, cols, start, end);
            if candidate < cost[end] { cost[end] = candidate; previous[end] = start; }
        }
    }
    let mut groups = 0i64;
    let mut cuts = 0u64;
    let mut end = cols;
    while end > 0 {
        let start = previous[end];
        if start > 0 { cuts |= 1u64 << (start - 1); }
        groups += 1;
        end = start;
    }
    if output.is_null() || capacity < OUTPUT { return -2; }
    let mut staged = [0u8; OUTPUT];
    put(&mut staged, 0, cost[cols]);
    put(&mut staged, 8, groups);
    put(&mut staged, 16, cuts as i64);
    std::ptr::copy_nonoverlapping(staged.as_ptr(), output, OUTPUT);
    OUTPUT as i64
}
