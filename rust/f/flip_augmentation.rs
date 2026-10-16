/// Flip grayscale pixels and reflect normalized bounding-box centers.
const MAX_INPUT_LENGTH: usize = 340;
const COORDINATE_SCALE: i64 = 1_000_000;

unsafe fn store_i32_le(output: *mut u8, position: usize, value: i32) {
    let bits = value as u32;
    for byte in 0..4 { *output.add(position + byte) = (bits >> (byte * 8)) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn flip_augmentation(values: *const i64, length: usize,
    output: *mut u8, output_capacity: usize) -> i64 {
    if values.is_null() || !(4..=MAX_INPUT_LENGTH).contains(&length) { return -1; }
    let values = std::slice::from_raw_parts(values, length);
    if !(1..=16).contains(&values[0]) || !(1..=16).contains(&values[1]) { return -1; }
    if !(0..=1).contains(&values[2]) || !(0..=16).contains(&values[3]) { return -1; }
    let width = values[0] as usize;
    let height = values[1] as usize;
    let flip_type = values[2] as usize;
    let box_count = values[3] as usize;
    let pixel_count = width * height;
    if length != 4 + pixel_count + 5 * box_count { return -1; }
    if values[4..4 + pixel_count].iter().any(|&pixel| !(0..=255).contains(&pixel)) { return -1; }
    for box_values in values[4 + pixel_count..].chunks_exact(5) {
        if !(0..=i32::MAX as i64).contains(&box_values[0]) { return -1; }
        if box_values[1..].iter().any(|&value| !(0..=COORDINATE_SCALE).contains(&value)) { return -1; }
    }
    let output_bytes = pixel_count + 20 * box_count;
    if output.is_null() || output_capacity < output_bytes { return -2; }

    for row in 0..height {
        for column in 0..width {
            let source_row = if flip_type == 0 { height - 1 - row } else { row };
            let source_column = if flip_type == 1 { width - 1 - column } else { column };
            *output.add(row * width + column) = values[4 + source_row * width + source_column] as u8;
        }
    }
    for box_index in 0..box_count {
        let base = 4 + pixel_count + 5 * box_index;
        let output_base = pixel_count + 20 * box_index;
        for field in 0..5 {
            let mut value = values[base + field];
            if flip_type == 1 && field == 1 { value = COORDINATE_SCALE - value; }
            if flip_type == 0 && field == 2 { value = COORDINATE_SCALE - value; }
            store_i32_le(output, output_base + 4 * field, value as i32);
        }
    }
    output_bytes as i64
}
