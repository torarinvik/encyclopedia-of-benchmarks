/// Port of TheAlgorithms/Java IterativeTernarySearch interval updates.
#[no_mangle]
pub extern "C" fn iterative_ternary_search(packed: *const i64, length: usize) -> i64 {
    if length < 2 {
        return -1;
    }
    let packed = unsafe { std::slice::from_raw_parts(packed, length) };
    let target = packed[0];
    let array = &packed[1..];
    if array.len() == 1 {
        return if array[0] == target { 0 } else { -1 };
    }

    let mut left = 0usize;
    let mut right = array.len() - 1;
    while right > left {
        if array[left] == target {
            return left as i64;
        }
        if array[right] == target {
            return right as i64;
        }
        let left_third = left + (right - left) / 3 + 1;
        let right_third = right - (right - left) / 3 - 1;
        if array[left_third] <= target {
            left = left_third;
        } else {
            right = right_third;
        }
    }
    -1
}
