/// Exact perfect-square check using bounded integer binary search.
#[no_mangle]
pub extern "C" fn perfect_square(input: i64) -> i64 {
    if input < 0 {
        return 0;
    }
    if input < 2 {
        return 1;
    }
    let number = input as u64;
    if ((0x0213_u64 >> (number & 15)) & 1) == 0 {
        return 0;
    }
    let mut low = 1_u64;
    let root_limit = if number <= u64::from(u32::MAX) { 65_535 } else { 3_037_000_499 };
    let mut high = (number / 2).min(root_limit);
    while low <= high {
        let middle = (low + high) >> 1;
        let square = middle * middle;
        if square == number {
            return 1;
        }
        if square < number {
            low = middle + 1;
        } else {
            high = middle - 1;
        }
    }
    0
}
