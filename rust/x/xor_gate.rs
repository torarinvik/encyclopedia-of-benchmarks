/// 1 when the inputs differ; otherwise 0.
#[no_mangle]
pub extern "C" fn xor_gate(left: u64, right: u64) -> i64 {
    (left ^ right) as i64
}
