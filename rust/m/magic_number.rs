/// Positive n is magic when its decimal digit root is one.
#[no_mangle]
pub extern "C" fn magic_number(n: i64) -> i64 {
    if n > 0 && n % 9 == 1 { 1 } else { 0 }
}
