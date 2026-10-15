/// Convert an ASCII Excel column title to its one-based column number.
#[no_mangle]
pub unsafe extern "C" fn excel_title_to_column(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 2 || length > 13 {
        return -1;
    }
    let values = std::slice::from_raw_parts(values, length);
    let count = values[0];
    if !(1..=12).contains(&count) || length != 1 + count as usize {
        return -1;
    }

    let mut column = 0_i64;
    for &value in &values[1..] {
        let letter = if (b'a' as i64..=b'z' as i64).contains(&value) {
            value - (b'a' - b'A') as i64
        } else {
            value
        };
        if !(b'A' as i64..=b'Z' as i64).contains(&letter) {
            return -1;
        }
        column = column * 26 + letter - b'A' as i64 + 1;
    }
    column
}
