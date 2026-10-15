/// Two-input Boolean AND over the benchmark's 0/1 domain.
#[no_mangle]
pub extern "C" fn and_gate(left: u64, right: u64) -> i64 {
    (left & right) as i64
}
