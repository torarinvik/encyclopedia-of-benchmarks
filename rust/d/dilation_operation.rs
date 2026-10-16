const INVALID_RESULT: i64 = i64::MIN;
const MAX_INPUT_LENGTH: usize = 2 + 16 * 16 + 9;

fn put_i32_le(output: &mut [u8], offset: usize, value: i32) {
    output[offset..offset + 4].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn dilation_operation(
    input: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || length < 12 || length > MAX_INPUT_LENGTH { return -1; }
    let input = std::slice::from_raw_parts(input, length);
    let rows_value = input[0];
    let columns_value = input[1];
    if !(1..=16).contains(&rows_value) || !(1..=16).contains(&columns_value) { return -1; }
    let rows = rows_value as usize;
    let columns = columns_value as usize;
    let cells = rows * columns;
    if length != 2 + cells + 9 { return -1; }
    if input[2..].iter().any(|&value| !(0..=1).contains(&value)) { return -1; }
    if output.is_null() || output_capacity < cells * 4 { return -2; }
    let output = std::slice::from_raw_parts_mut(output, output_capacity);
    for y in 0..rows {
        for x in 0..columns {
            let mut sum = 0i32;
            for ky in 0..3 {
                for kx in 0..3 {
                    let image_y = y as isize + ky as isize - 1;
                    let image_x = x as isize + kx as isize - 1;
                    if image_y >= 0 && image_y < rows as isize && image_x >= 0 && image_x < columns as isize {
                        sum += (input[2 + image_y as usize * columns + image_x as usize] * input[2 + cells + ky * 3 + kx]) as i32;
                    }
                }
            }
            put_i32_le(output, (y * columns + x) * 4, if sum > 0 { 1 } else { 0 });
        }
    }
    cells as i64
}
