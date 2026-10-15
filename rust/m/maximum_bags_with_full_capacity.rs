fn sift_down(values: &mut [i64], mut root: usize, end: usize) {
    while root < end / 2 {
        let mut child = root * 2 + 1;
        if child + 1 < end && values[child] < values[child + 1] {
            child += 1;
        }
        if values[root] >= values[child] {
            break;
        }
        values.swap(root, child);
        root = child;
    }
}

/// Sort the free-space requirements and fill the least expensive bags first.
#[no_mangle]
pub unsafe extern "C" fn maximum_bags_with_full_capacity(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(2..=16_384).contains(&length) { return -1; }
    let mut remaining = *input;
    if !(0..=1_000_000_000).contains(&remaining) { return -1; }
    let count_arg = *input.add(1);
    if !(0..=8_191).contains(&count_arg) { return -1; }
    let count = count_arg as usize;
    if length != 2 + 2 * count { return -1; }
    let mut deficits = [0i64; 8_191];
    for index in 0..count {
        let capacity = *input.add(2 + index);
        let rocks = *input.add(2 + count + index);
        if !(1..=100_000).contains(&capacity) || rocks < 0 || rocks > capacity { return -1; }
        deficits[index] = capacity - rocks;
    }
    for start in (0..(count / 2)).rev() {
        sift_down(&mut deficits, start, count);
    }
    for end in (1..count).rev() {
        deficits.swap(0, end);
        sift_down(&mut deficits, 0, end);
    }
    let mut full_bags = 0i64;
    for &deficit in &deficits[..count] {
        if deficit > remaining { break; }
        remaining -= deficit;
        full_bags += 1;
    }
    full_bags
}
