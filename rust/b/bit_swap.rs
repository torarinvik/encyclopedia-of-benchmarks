/// Swap two 0-based bits in a signed 32-bit value.
#[no_mangle]
pub unsafe extern "C" fn bit_swap(values: *const i64, length: usize) -> i64 {
    if length != 3 || values.is_null() { return -2_147_483_649; }
    let values = std::slice::from_raw_parts(values, length);
    let data = values[0];
    let pos_a = values[1];
    let pos_b = values[2];
    if !(i32::MIN as i64..=i32::MAX as i64).contains(&data)
        || !(0..=31).contains(&pos_a) || !(0..=31).contains(&pos_b) { return -2_147_483_649; }
    let mut bits = data as i32 as u32;
    let mask_a = 1u32 << (pos_a as u32);
    let mask_b = 1u32 << (pos_b as u32);
    let bit_a = (bits >> (pos_a as u32)) & 1;
    let bit_b = (bits >> (pos_b as u32)) & 1;
    if bit_a != bit_b { bits ^= mask_a ^ mask_b; }
    bits as i32 as i64
}
