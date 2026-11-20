const MAX_ROWS: usize = 8;
const MAX_COLUMNS: usize = 8;
const NO_FEASIBLE: i64 = -1025;
const INVALID_INPUT: i64 = -1026;

fn best_subarray_at_most(values: &[i64], limit: i64) -> Option<i64> {
    let mut prefixes = [0_i64; MAX_COLUMNS + 1];
    let mut prefix_count = 1_usize;
    let mut running = 0_i64;
    let mut best: Option<i64> = None;
    for &value in values {
        running += value;
        let threshold = running - limit;
        let mut low = 0_usize;
        let mut high = prefix_count;
        while low < high {
            let middle = low + (high - low) / 2;
            if prefixes[middle] < threshold { low = middle + 1; }
            else { high = middle; }
        }
        if low < prefix_count {
            let candidate = running - prefixes[low];
            if best.map_or(true, |old| candidate > old) { best = Some(candidate); }
        }
        let mut insert = prefix_count;
        while insert > 0 && prefixes[insert - 1] > running {
            prefixes[insert] = prefixes[insert - 1];
            insert -= 1;
        }
        prefixes[insert] = running;
        prefix_count += 1;
    }
    best
}

#[no_mangle]
pub unsafe extern "C" fn max_sum_rectangle_no_larger_than_k(
    input: *const i64,
    length: usize,
) -> i64 {
    if input.is_null() || length < 3 || length > 68 { return INVALID_INPUT; }
    let values = std::slice::from_raw_parts(input, length);
    let rows_value = values[0];
    let columns_value = values[1];
    let limit = values[2];
    if rows_value < 1 || rows_value > MAX_ROWS as i64
        || columns_value < 1 || columns_value > MAX_COLUMNS as i64
        || limit < -1024 || limit > 1024 { return INVALID_INPUT; }
    let rows = rows_value as usize;
    let columns = columns_value as usize;
    if length != 3 + rows * columns { return INVALID_INPUT; }

    let mut matrix = [[0_i64; MAX_COLUMNS]; MAX_ROWS];
    for row in 0..rows {
        for column in 0..columns {
            let value = values[3 + row * columns + column];
            if !(-16..=16).contains(&value) { return INVALID_INPUT; }
            matrix[row][column] = value;
        }
    }
    let short_dimension = rows.min(columns);
    let long_dimension = rows.max(columns);
    let mut best: Option<i64> = None;
    for first in 0..short_dimension {
        let mut compressed = [0_i64; MAX_COLUMNS];
        for last in first..short_dimension {
            for offset in 0..long_dimension {
                compressed[offset] += if rows <= columns {
                    matrix[last][offset]
                } else {
                    matrix[offset][last]
                };
            }
            if let Some(candidate) = best_subarray_at_most(&compressed[..long_dimension], limit) {
                if best.map_or(true, |old| candidate > old) {
                    best = Some(candidate);
                    if candidate == limit { return candidate; }
                }
            }
        }
    }
    best.unwrap_or(NO_FEASIBLE)
}
