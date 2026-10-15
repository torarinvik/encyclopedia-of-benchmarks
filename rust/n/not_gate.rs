/// Return the logical complement on the Boolean 0/1 domain.
#[no_mangle]
pub extern "C" fn not_gate(value: i64) -> i64 {
    if value == 0 { 1 } else { 0 }
}
