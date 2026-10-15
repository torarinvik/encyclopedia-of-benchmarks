/// Return the parity of the set-bit count using Kernighan's bit clearing.
#[no_mangle]
pub extern "C" fn parity(number: i64) -> i64 {
    if number < 0 { return -1; }
    let mut current = number;
    let mut result = 0_i64;
    while current != 0 {
        result ^= 1;
        current &= current - 1;
    }
    result
}
