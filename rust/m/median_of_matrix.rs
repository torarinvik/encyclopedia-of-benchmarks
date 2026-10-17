const MAX_ROWS: usize = 16;
const MAX_CELLS: usize = 128;
const MAX_INPUT_WORDS: usize = 1 + MAX_ROWS + MAX_CELLS;

#[no_mangle]
pub unsafe extern "C" fn median_of_matrix(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || !(1..=MAX_INPUT_WORDS).contains(&length) {
        return -1;
    }
    let words = std::slice::from_raw_parts(input, length);
    if !(0..=MAX_ROWS as i64).contains(&words[0]) {
        return -1;
    }

    let row_count = words[0] as usize;
    let mut cursor = 1usize;
    let mut values = [0i32; MAX_CELLS];
    let mut value_count = 0usize;
    for _ in 0..row_count {
        if cursor >= length {
            return -1;
        }
        let row_length = words[cursor];
        cursor += 1;
        if row_length == -1 {
            continue;
        }
        if !(0..=MAX_CELLS as i64).contains(&row_length) {
            return -1;
        }
        let cells = row_length as usize;
        if cells > MAX_CELLS - value_count || cells > length - cursor {
            return -1;
        }
        for _ in 0..cells {
            let value = words[cursor];
            cursor += 1;
            if value < i32::MIN as i64 || value > i32::MAX as i64 {
                return -1;
            }
            values[value_count] = value as i32;
            value_count += 1;
        }
    }
    if cursor != length || value_count == 0 {
        return -1;
    }
    values[..value_count].sort();

    if output.is_null() || capacity < 4 {
        return -2;
    }
    let bytes = values[(value_count - 1) / 2].to_le_bytes();
    std::ptr::copy_nonoverlapping(bytes.as_ptr(), output, bytes.len());
    4
}
