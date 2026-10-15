#[no_mangle]
pub extern "C" fn kynea_numbers(index: i64) -> i64 {
    if !(1..=31).contains(&index) {
        return -1;
    }
    let value = (1i64 << index as u32) + 1;
    let square = value * value;
    square - 2
}
