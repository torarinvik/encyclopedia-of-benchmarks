/// Java int addition by recursive XOR and shifted carry, modulo 2^32.
fn add_recursive(a: u32, b: u32) -> u32 {
    if b == 0 { a } else { add_recursive(a ^ b, (a & b) << 1) }
}

#[no_mangle]
pub extern "C" fn sum_without_arithmetic_operators(a: i64, b: i64) -> i64 {
    if !(i32::MIN as i64..=i32::MAX as i64).contains(&a) || !(i32::MIN as i64..=i32::MAX as i64).contains(&b) { return -2_147_483_649; }
    let bits = add_recursive(a as i32 as u32, b as i32 as u32);
    bits as i32 as i64
}
