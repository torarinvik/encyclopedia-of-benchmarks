/// Generate Floyd's triangle as flattened little-endian 16-bit values.
const MAX_ROWS: i64 = 90;

#[no_mangle]
pub unsafe extern "C" fn floyd_triangle(rows: i64, output: *mut u8,
    output_capacity: usize) -> i64 {
    if !(0..=MAX_ROWS).contains(&rows) { return -1; }
    let row_count = rows as usize;
    let count = row_count * (row_count + 1) / 2;
    let output_length = count * 2;
    if output_capacity < output_length || (output_length != 0 && output.is_null()) { return -2; }

    let mut index = 0usize;
    let mut number = 1u16;
    for row in 1..=row_count {
        for _ in 0..row {
            *output.add(index * 2) = (number & 0xff) as u8;
            *output.add(index * 2 + 1) = (number >> 8) as u8;
            number += 1;
            index += 1;
        }
    }
    output_length as i64
}
