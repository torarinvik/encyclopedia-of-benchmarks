/// Two-input Boolean implication over the benchmark's 0/1 domain.
#[no_mangle]
pub extern "C" fn imply_gate(left: u64, right: u64) -> i64 {
    (left == 0 || right == 1) as i64
}
