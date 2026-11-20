const MAX_LENGTH: usize = 64;
const MAX_HEIGHT: i64 = 1_000_000;

#[no_mangle]
pub unsafe extern "C" fn hanging_line_largest_rectangle(heights: *const i64, length: usize) -> i64 {
    if length == 0 { return 0; }
    if heights.is_null() || length > MAX_LENGTH { return i64::MIN; }
    let heights = unsafe { std::slice::from_raw_parts(heights, length) };
    if heights.iter().any(|&height| !(0..=MAX_HEIGHT).contains(&height)) { return i64::MIN; }

    let mut left = [0usize; MAX_LENGTH];
    let mut right = [0usize; MAX_LENGTH];
    for i in 0..length {
        left[i] = i;
        while left[i] > 0 && heights[i] <= heights[left[i] - 1] {
            left[i] = left[left[i] - 1];
        }
    }
    for i in (0..length).rev() {
        right[i] = i;
        while right[i] + 1 < length && heights[i] <= heights[right[i] + 1] {
            right[i] = right[right[i] + 1];
        }
    }

    let mut best = 0i64;
    for i in 0..length {
        let width = (right[i] - left[i] + 1) as i64;
        best = best.max(heights[i] * width);
    }
    best
}
