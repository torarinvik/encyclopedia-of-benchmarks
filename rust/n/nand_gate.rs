/// 1 only when at least one input is 0; 0 when both are 1.
#[no_mangle]
pub extern "C" fn nand_gate(left: u64, right: u64) -> i64 {
    (1 - (left & right)) as i64
}
