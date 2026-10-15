/// Two-pointer maximum area between vertical lines.
#[no_mangle]
pub extern "C" fn container_with_most_water(heights: *const i64, length: usize) -> i64 {
    if length > 4096 { return -1; }
    if length == 0 { return 0; }
    let heights = unsafe { std::slice::from_raw_parts(heights, length) };
    if heights.iter().any(|&height| height < 0 || height > i32::MAX as i64) {
        return -1;
    }
    if length < 2 { return 0; }

    let mut left = 0usize;
    let mut right = length - 1;
    let mut best = 0i64;
    while left < right {
        let left_height = heights[left];
        let right_height = heights[right];
        let height = left_height.min(right_height);
        let area = height * (right - left) as i64;
        if area > best { best = area; }
        if left_height <= right_height { left += 1; }
        else { right -= 1; }
    }
    best
}
