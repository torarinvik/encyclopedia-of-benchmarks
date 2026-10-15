/// Check whether a signed 32-bit integer is a perfect square.
#[no_mangle]
pub extern "C" fn perfect_square_checker(n: i64) -> i64 {
    if n < i32::MIN as i64 || n > i32::MAX as i64 {
        return -1;
    }
    if n < 0 {
        return 0;
    }

    let mut low = 0i64;
    let mut high = 46_340i64;
    while low <= high {
        let mid = low + (high - low) / 2;
        let square = mid * mid;
        if square == n {
            return 1;
        }
        if square < n {
            low = mid + 1;
        } else {
            high = mid - 1;
        }
    }
    0
}
