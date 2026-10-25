const MAX_ROWS: usize = 8;
const MAX_COLS: usize = 8;
const MAX_CELLS: usize = MAX_ROWS * MAX_COLS;
const MAX_INPUT_LENGTH: usize = 2 + 2 * MAX_CELLS;
const BYTES_PER_VALUE: usize = 8;

fn store_i64_le(output: *mut u8, position: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..BYTES_PER_VALUE {
        unsafe { output.add(position + byte).write((bits >> (byte * 8)) as u8); }
    }
}

#[no_mangle]
pub unsafe extern "C" fn tsvc_s343_column_major_compaction(
    input: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || length < 4 || length > MAX_INPUT_LENGTH {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, length);
    let rows_raw = values[0];
    let cols_raw = values[1];
    if rows_raw < 1 || rows_raw > MAX_ROWS as i64 || cols_raw < 1 || cols_raw > MAX_COLS as i64 {
        return -1;
    }
    let rows = rows_raw as usize;
    let cols = cols_raw as usize;
    let cells = rows * cols;
    if length != 2 + 2 * cells {
        return -1;
    }
    if output.is_null() || output_capacity < cells * BYTES_PER_VALUE {
        return -2;
    }

    let data = &values[2..2 + cells];
    let mask = &values[2 + cells..];
    let mut written = 0usize;
    for col in 0..cols {
        for row in 0..rows {
            let index = row * cols + col;
            if mask[index] > 0 {
                store_i64_le(output, written * BYTES_PER_VALUE, data[index]);
                written += 1;
            }
        }
    }
    written as i64
}
