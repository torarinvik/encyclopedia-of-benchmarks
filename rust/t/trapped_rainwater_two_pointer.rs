#[no_mangle]
pub unsafe extern "C" fn trapped_rainwater_two_pointer(heights: *const i64, length: usize) -> i64 {
    if length > 4096 || (length != 0 && heights.is_null()) { return -1; }
    let values = if length == 0 { &[] } else { std::slice::from_raw_parts(heights, length) };
    if values.iter().any(|&h| !(0..=1_000_000).contains(&h)) { return -1; }
    if length <= 2 { return 0; }
    let (mut left, mut right) = (0usize, length - 1);
    let (mut left_max, mut right_max, mut trapped) = (0u32, 0u32, 0u32);
    while left < right {
        if values[left] < values[right] {
            let h = values[left] as u32;
            if h >= left_max { left_max = h; } else { trapped += left_max - h; }
            left += 1;
        } else {
            let h = values[right] as u32;
            if h >= right_max { right_max = h; } else { trapped += right_max - h; }
            right -= 1;
        }
    }
    trapped as i64
}
