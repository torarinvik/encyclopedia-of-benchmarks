/// Process the smaller endpoint, validating each bar as it enters the window.
#[no_mangle]
pub unsafe extern "C" fn trapped_rainwater_two_pointer(heights: *const i64, length: usize) -> i64 {
    if length > 4096 || (length != 0 && heights.is_null()) { return -1; }
    if length == 0 { return 0; }

    let values = std::slice::from_raw_parts(heights, length);
    let (mut left, mut right) = (0, length - 1);
    let (mut left_height, mut right_height) = (values[left] as u64, values[right] as u64);
    if left_height > 1_000_000 || right_height > 1_000_000 { return -1; }

    let (mut left_max, mut right_max, mut trapped) = (0_u32, 0_u32, 0_u32);
    while left < right {
        if left_height < right_height {
            let height = left_height as u32;
            left_max = left_max.max(height);
            trapped += left_max - height;
            left += 1;
            left_height = values[left] as u64;
            if left_height > 1_000_000 { return -1; }
        } else {
            let height = right_height as u32;
            right_max = right_max.max(height);
            trapped += right_max - height;
            right -= 1;
            right_height = values[right] as u64;
            if right_height > 1_000_000 { return -1; }
        }
    }
    i64::from(trapped)
}
