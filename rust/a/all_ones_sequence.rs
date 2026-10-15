#[no_mangle]
pub extern "C" fn all_ones_sequence(index: i64) -> i64 {
    if index < 0 { -1 } else { 1 }
}
