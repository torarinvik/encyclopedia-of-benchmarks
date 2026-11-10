#[no_mangle]
pub extern "C" fn hamming_distance(left: u64, right: u64) -> i64 {
    i64::from((left ^ right).count_ones())
}
