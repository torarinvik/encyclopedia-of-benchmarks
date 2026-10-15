/// 1 when the inputs are equal; otherwise 0.
#[no_mangle]
pub extern "C" fn xnor_gate(left: u64, right: u64) -> i64 {
    (1 - (left ^ right)) as i64
}
