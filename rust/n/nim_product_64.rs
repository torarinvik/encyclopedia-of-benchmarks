fn nim_product(a: u64, b: u64, width: u32) -> u64 {
    if width == 1 { return a & b; }
    let half = width / 2;
    let mask = (1u64 << half) - 1;
    let a_low = a & mask;
    let a_high = a >> half;
    let b_low = b & mask;
    let b_high = b >> half;
    let low_product = nim_product(a_low, b_low, half);
    let high_product = nim_product(a_high, b_high, half);
    let cross = nim_product(a_low ^ a_high, b_low ^ b_high, half)
              ^ low_product ^ high_product;
    let constant = 1u64 << (half - 1);
    let low = low_product ^ nim_product(high_product, constant, half);
    let high = cross ^ high_product;
    low ^ (high << half)
}

#[no_mangle]
pub unsafe extern "C" fn nim_product_64(
    input: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || length != 4 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if values.iter().any(|&value| !(0..=4_294_967_295).contains(&value)) { return -1; }
    if output.is_null() || output_capacity < 8 { return -2; }

    let a = values[0] as u64 | ((values[1] as u64) << 32);
    let b = values[2] as u64 | ((values[3] as u64) << 32);
    let result = nim_product(a, b, 64);
    for index in 0..8 {
        unsafe { *output.add(index) = (result >> (8 * index)) as u8; }
    }
    8
}
