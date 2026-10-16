fn put_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        unsafe { *output.add(offset + byte) = (bits >> (byte * 8)) as u8; }
    }
}

fn sift_down(values: &mut [i64], mut root: usize, end: usize) {
    while root < end / 2 {
        let mut child = root * 2 + 1;
        if child + 1 < end && values[child] < values[child + 1] { child += 1; }
        if values[root] >= values[child] { break; }
        values.swap(root, child);
        root = child;
    }
}

fn heap_sort(values: &mut [i64]) {
    let length = values.len();
    for start in (1..=length / 2).rev() { sift_down(values, start - 1, length); }
    for end in (2..=length).rev() {
        values.swap(0, end - 1);
        sift_down(values, 0, end - 1);
    }
}

#[no_mangle]
pub unsafe extern "C" fn triplet_sum_two_pointer(
    input: *const i64, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    const MAX_ITEMS: usize = 1024;
    if input.is_null() || length < 1 || length > MAX_ITEMS + 1 { return -1; }
    let target = *input;
    if !(-3_000_000..=3_000_000).contains(&target) { return -1; }
    let item_count = length - 1;
    let mut values = [0i64; MAX_ITEMS];
    for index in 0..item_count {
        let value = *input.add(index + 1);
        if !(-1_000_000..=1_000_000).contains(&value) { return -1; }
        values[index] = value;
    }
    if output_capacity < 24 || output.is_null() { return -2; }
    heap_sort(&mut values[..item_count]);

    let mut result = [0i64; 3];
    'search: for first in 0..item_count.saturating_sub(2) {
        let mut left = first + 1;
        let mut right = item_count - 1;
        while left < right {
            let sum = values[first] + values[left] + values[right];
            if sum == target {
                result = [values[first], values[left], values[right]];
                break 'search;
            }
            if sum < target { left += 1; } else { right -= 1; }
        }
    }
    for index in 0..3 { put_i64_le(output, index * 8, result[index]); }
    3
}
