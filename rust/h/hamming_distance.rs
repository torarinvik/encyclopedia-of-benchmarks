/// Portable Hamming distance over two unsigned 64-bit values.
#[no_mangle]
pub extern "C" fn hamming_distance(mut left: u64, mut right: u64) -> i64 {
    let mut count = 0i64;
    while left != 0 || right != 0 {
        if (left & 1) != (right & 1) { count += 1; }
        left >>= 1;
        right >>= 1;
    }
    count
}
