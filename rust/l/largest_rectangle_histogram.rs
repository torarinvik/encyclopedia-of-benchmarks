/// Largest rectangle area in a bounded histogram.
const MAX_INPUT_LENGTH: usize = 64;

#[no_mangle]
pub unsafe extern "C" fn largest_rectangle_histogram(heights: *const i64, length: usize) -> i64 {
    if length == 0 { return 0; }
    if heights.is_null() || length > MAX_INPUT_LENGTH { return i64::MIN; }
    let heights = unsafe { std::slice::from_raw_parts(heights, length) };
    if heights.iter().any(|&height| !(0..=1_000_000).contains(&height)) { return i64::MIN; }

    let mut stack = [0usize; MAX_INPUT_LENGTH];
    let mut top = 0usize;
    let mut best = 0i64;
    for index in 0..length {
        while top > 0 && heights[stack[top - 1]] > heights[index] {
            top -= 1;
            let bar = stack[top];
            let left = if top == 0 { 0 } else { stack[top - 1] + 1 };
            best = best.max(heights[bar] * (index - left) as i64);
        }
        stack[top] = index;
        top += 1;
    }
    while top > 0 {
        top -= 1;
        let bar = stack[top];
        let left = if top == 0 { 0 } else { stack[top - 1] + 1 };
        best = best.max(heights[bar] * (length - left) as i64);
    }
    best
}
