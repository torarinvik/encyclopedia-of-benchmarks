/// Floor square root by binary search, with division avoiding square overflow.
#[no_mangle]
pub extern "C" fn square_root_binary_search(value: i64) -> i64 {
    if value < 0 { return -1; }
    if value < 2 { return value; }
    let mut low = 1_i64;
    let mut high = value;
    let mut answer = 0_i64;
    while low <= high {
        let middle = low + (high - low) / 2;
        if middle <= value / middle {
            answer = middle;
            low = middle + 1;
        } else {
            high = middle - 1;
        }
    }
    answer
}
