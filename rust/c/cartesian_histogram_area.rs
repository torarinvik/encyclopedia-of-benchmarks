// Uncompiled and unexecuted Cartesian-tree histogram draft.
#[no_mangle]
pub unsafe extern "C" fn cartesian_histogram_area(heights: *const i64, length: usize) -> i64 {
    if length == 0 { return 0; }
    if heights.is_null() || length > 64 { return i64::MIN; }
    let values = std::slice::from_raw_parts(heights, length);
    if values.iter().any(|&x| !(0..=1_000_000).contains(&x)) { return i64::MIN; }
    let mut left = [length; 64];
    let mut right = [length; 64];
    let mut stack = [0usize; 64];
    let mut order = [0usize; 64];
    let mut sizes = [0usize; 64];
    let mut top = 0;
    for i in 0..length {
        let mut last = length;
        while top > 0 && values[stack[top-1]] > values[i] { top -= 1; last = stack[top]; }
        if top > 0 { right[stack[top-1]] = i; }
        left[i] = last; stack[top] = i; top += 1;
    }
    let root = stack[0];
    top = 1; stack[0] = root;
    let mut used = 0;
    while top > 0 {
        top -= 1; let node = stack[top]; order[used] = node; used += 1;
        if left[node] < length { stack[top] = left[node]; top += 1; }
        if right[node] < length { stack[top] = right[node]; top += 1; }
    }
    let mut best = 0;
    while used > 0 {
        used -= 1; let node = order[used];
        sizes[node] = 1 + (if left[node] < length { sizes[left[node]] } else { 0 })
                        + (if right[node] < length { sizes[right[node]] } else { 0 });
        best = best.max(values[node]*sizes[node] as i64);
    }
    best
}
