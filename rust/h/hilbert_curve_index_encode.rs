const MAX_ORDER: i64 = 8;

fn hilbert_index(order: i64, x: i64, y: i64) -> i64 {
    let (mut current_x, mut current_y) = (x, y);
    let mut distance = 0i64;
    for bit_index in (0..order).rev() {
        let bit = 1i64 << bit_index;
        let x_bit = i64::from(current_x & bit != 0);
        let y_bit = i64::from(current_y & bit != 0);
        distance += bit * bit * ((3 * x_bit) ^ y_bit);
        let mask = bit - 1;
        let (mut low_x, mut low_y) = (current_x & mask, current_y & mask);
        if y_bit == 0 {
            if x_bit != 0 {
                low_x = mask - low_x;
                low_y = mask - low_y;
            }
            (current_x, current_y) = (low_y, low_x);
        } else {
            (current_x, current_y) = (low_x, low_y);
        }
    }
    distance
}

fn store_i64_le(output: *mut u8, value: i64) {
    let bytes = value.to_le_bytes();
    unsafe { std::ptr::copy_nonoverlapping(bytes.as_ptr(), output, 8); }
}

#[no_mangle]
pub unsafe extern "C" fn hilbert_curve_index_encode(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length != 3 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let order = values[0];
    if !(1..=MAX_ORDER).contains(&order) { return -1; }
    let side = 1i64 << order;
    let (x, y) = (values[1], values[2]);
    if x < 0 || x >= side || y < 0 || y >= side { return -1; }
    if output.is_null() || capacity < 8 { return -2; }
    store_i64_le(output, hilbert_index(order, x, y));
    8
}
