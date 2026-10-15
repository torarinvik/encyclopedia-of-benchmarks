/// Sum trapped water using per-position prefix and suffix maxima.
#[no_mangle]
pub extern "C" fn trapped_rainwater(heights: *const i64, length: usize) -> i64 {
    if length > 4096 || (length != 0 && heights.is_null()) { return -1; }
    if length == 0 { return 0; }
    let heights = unsafe { std::slice::from_raw_parts(heights, length) };
    if heights.iter().any(|&height| !(0..=1_000_000).contains(&height)) { return -1; }
    if length < 3 { return 0; }

    let mut left_max = [0i64; 4096];
    let mut right_max = [0i64; 4096];
    left_max[0] = heights[0];
    for index in 1..length { left_max[index] = left_max[index - 1].max(heights[index]); }
    right_max[length - 1] = heights[length - 1];
    for index in (0..length - 1).rev() { right_max[index] = right_max[index + 1].max(heights[index]); }

    let mut water = 0i64;
    for index in 0..length { water += left_max[index].min(right_max[index]) - heights[index]; }
    water
}
