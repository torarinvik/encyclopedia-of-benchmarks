#[no_mangle]
pub extern "C" fn imply_gate(left: u64, right: u64) -> i64 {
    if left > 1 || right > 1 { return -1; }
    i64::from(left == 0 || right == 1)
}
