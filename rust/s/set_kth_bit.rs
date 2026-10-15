#[no_mangle]
pub unsafe extern "C" fn set_kth_bit(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length != 2 {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, 2);
    let (number, bit) = (values[0], values[1]);
    if !(0..=2_147_483_647).contains(&number) || !(0..=30).contains(&bit) {
        return -1;
    }
    number | (1_i64 << bit)
}
