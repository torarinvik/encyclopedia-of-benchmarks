/// Add nonnegative integers by recursively propagating XOR carries.
fn add_recursive(first: i64, second: i64) -> i64 {
    let bitwise_sum = first ^ second;
    let carry = first & second;
    if carry == 0 { bitwise_sum } else { add_recursive(bitwise_sum, carry << 1) }
}

#[no_mangle]
pub extern "C" fn bitwise_addition_recursive(first: i64, second: i64) -> i64 {
    if !(0..=2_147_483_647).contains(&first) || !(0..=2_147_483_647).contains(&second) { return -1; }
    add_recursive(first, second)
}
