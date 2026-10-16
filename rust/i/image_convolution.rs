const MAX_SIDE: usize = 16;
const MAX_KERNEL_SIDE: usize = 7;

fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bytes = value.to_le_bytes();
    for (index, byte) in bytes.iter().enumerate() {
        unsafe { *output.add(offset + index) = *byte; }
    }
}

#[no_mangle]
pub unsafe extern "C" fn image_convolution(
    values: *const i64, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if values.is_null() || length < 3 || length > 308 { return -1; }
    let input = std::slice::from_raw_parts(values, length);
    let (side_value, kernel_side_value) = (input[0], input[1]);
    if side_value < 1 || side_value > MAX_SIDE as i64 || kernel_side_value < 1 ||
       kernel_side_value > MAX_KERNEL_SIDE as i64 || kernel_side_value % 2 == 0 { return -1; }
    let side = side_value as usize;
    let kernel_side = kernel_side_value as usize;
    let pixel_count = side * side;
    let kernel_count = kernel_side * kernel_side;
    if length != 2 + pixel_count + kernel_count { return -1; }
    if input[2..2 + pixel_count].iter().any(|&pixel| !(0..=255).contains(&pixel)) { return -1; }
    if input[2 + pixel_count..].iter().any(|&weight| !(-16..=16).contains(&weight)) { return -1; }
    let output_bytes = pixel_count * 8;
    if output.is_null() || output_capacity < output_bytes { return -2; }

    let radius = (kernel_side / 2) as isize;
    for row in 0..side {
        for column in 0..side {
            let mut total = 0_i64;
            for kernel_row in 0..kernel_side {
                let source_row = (row as isize + kernel_row as isize - radius).clamp(0, side as isize - 1) as usize;
                for kernel_column in 0..kernel_side {
                    let source_column = (column as isize + kernel_column as isize - radius).clamp(0, side as isize - 1) as usize;
                    let pixel = input[2 + source_row * side + source_column];
                    let weight = input[2 + pixel_count + kernel_row * kernel_side + kernel_column];
                    total += pixel * weight;
                }
            }
            store_i64_le(output, (row * side + column) * 8, total);
        }
    }
    output_bytes as i64
}
