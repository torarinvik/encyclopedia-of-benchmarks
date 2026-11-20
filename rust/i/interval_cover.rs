/// Greedy minimum subfamily covering a half-open target interval.
#[no_mangle]
pub extern "C" fn interval_cover(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(3..=36).contains(&length) { return -2; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let target_left = values[0];
    let target_right = values[1];
    let count_value = values[2];
    if target_left < 0 || target_left > target_right || target_right > 32
        || !(0..=16).contains(&count_value) { return -2; }
    let count = count_value as usize;
    if length != 3 + 2 * count { return -2; }
    for index in 0..count {
        let left = values[3 + 2 * index];
        let right = values[4 + 2 * index];
        if left < 0 || left >= right || right > 32 { return -2; }
    }
    if target_left == target_right { return 0; }

    let mut frontier = target_left;
    let mut selected = 0i64;
    while frontier < target_right {
        let mut farthest = frontier;
        for index in 0..count {
            let left = values[3 + 2 * index];
            let right = values[4 + 2 * index];
            if left <= frontier && right > farthest { farthest = right; }
        }
        if farthest == frontier { return -1; }
        frontier = farthest;
        selected += 1;
    }
    selected
}
