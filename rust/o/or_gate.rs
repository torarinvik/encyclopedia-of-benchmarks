/// 1 when either input is 1; otherwise 0.
#[no_mangle]
pub extern "C" fn or_gate(left: u64, right: u64) -> i64 {
    (left | right) as i64
}
