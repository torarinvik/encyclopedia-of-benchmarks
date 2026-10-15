/// Maximize the sum of a contiguous window with distinct values.
#[no_mangle]
pub extern "C" fn maximum_unique_subarray(values: *const i64, length: usize) -> i64 {
    if length > 256 {
        return -1;
    }
    if length == 0 {
        return 0;
    }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    let mut keys = [0i64; 512];
    let mut last_seen = [0usize; 512];
    let mut occupied = [false; 512];
    let mut left = 0usize;
    let mut window_sum = 0i64;
    let mut best = 0i64;
    for (index, &value) in values.iter().enumerate() {
        if !(1..=10_000).contains(&value) {
            return -1;
        }
        let mut slot = value as usize % 512;
        while occupied[slot] && keys[slot] != value {
            slot = (slot + 1) % 512;
        }
        let previous = last_seen[slot];
        while left < previous {
            window_sum -= values[left];
            left += 1;
        }
        window_sum += value;
        keys[slot] = value;
        last_seen[slot] = index + 1;
        occupied[slot] = true;
        best = best.max(window_sum);
    }
    best
}
