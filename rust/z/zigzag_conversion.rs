/// Arrange ASCII letters in zigzag rows and read them row by row.
const MAX_INPUT_LENGTH: usize = 1025;
const MAX_ROWS: i64 = 1024;

fn is_ascii_letter(value: i64) -> bool {
    (65..=90).contains(&value) || (97..=122).contains(&value)
}

#[no_mangle]
pub unsafe extern "C" fn zigzag_conversion(values: *const i64, length: usize,
    output: *mut u8, output_capacity: usize) -> i64 {
    if length == 0 || length > MAX_INPUT_LENGTH || values.is_null() { return -1; }
    let rows_value = *values;
    if !(1..=MAX_ROWS).contains(&rows_value) { return -1; }
    let text_length = length - 1;
    for index in 0..text_length {
        if !is_ascii_letter(*values.add(index + 1)) { return -1; }
    }
    if output_capacity < text_length || (text_length != 0 && output.is_null()) { return -2; }
    if text_length == 0 { return 0; }
    let rows = rows_value as usize;
    if rows == 1 || rows >= text_length {
        for index in 0..text_length { *output.add(index) = *values.add(index + 1) as u8; }
        return text_length as i64;
    }
    let cycle = 2 * (rows - 1);
    let mut written = 0;
    for row in 0..rows {
        let mut index = row;
        let mut step = if row == 0 || row + 1 == rows { cycle } else { cycle - 2 * row };
        while index < text_length {
            *output.add(written) = *values.add(index + 1) as u8;
            written += 1;
            index += step;
            if row > 0 && row + 1 < rows { step = cycle - step; }
        }
    }
    written as i64
}
