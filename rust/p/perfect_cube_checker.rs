/// Check whether a signed 32-bit integer is a perfect cube.
#[no_mangle]
pub extern "C" fn perfect_cube_checker(n: i64) -> i64 {
    if n < i32::MIN as i64 || n > i32::MAX as i64 {
        return -1;
    }

    let magnitude = n.abs();
    let mut low = 0i64;
    let mut high = 1290i64;
    while low <= high {
        let mid = low + (high - low) / 2;
        let cube = mid * mid * mid;
        if cube == magnitude {
            return 1;
        }
        if cube < magnitude {
            low = mid + 1;
        } else {
            high = mid - 1;
        }
    }
    0
}
