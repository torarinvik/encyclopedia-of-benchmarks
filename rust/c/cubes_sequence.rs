#[no_mangle]
pub extern "C" fn cubes_sequence(index: i64) -> i64 {
    if !(0..=2_097_151).contains(&index) {
        return -1;
    }
    index * index * index
}
