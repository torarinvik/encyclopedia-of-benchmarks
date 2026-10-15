/// Return unique sorted target-sum triplets using sort-and-two-pointers.
const MAX_ITEMS: usize = 257;
const BYTES_PER_TRIPLET: usize = 12;

fn sift_down(values: &mut [i64; MAX_ITEMS], mut root: usize, end: usize) {
    while root < end / 2 {
        let mut child = root * 2 + 1;
        if child + 1 < end && values[child] < values[child + 1] { child += 1; }
        if values[root] >= values[child] { break; }
        values.swap(root, child);
        root = child;
    }
}

fn heap_sort(values: &mut [i64; MAX_ITEMS], length: usize) {
    for start in (0..length / 2).rev() { sift_down(values, start, length); }
    for end in (1..length).rev() {
        values.swap(0, end);
        sift_down(values, 0, end);
    }
}

unsafe fn store_i32_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as i32 as u32;
    for byte in 0..4 {
        *output.add(offset + byte) = (bits >> (byte * 8)) as u8;
    }
}

unsafe fn enumerate_triplets(values: &[i64; MAX_ITEMS], length: usize, target: i64,
                             output: *mut u8, write_output: bool) -> usize {
    let mut result_count = 0;
    for first in 0..length.saturating_sub(2) {
        if first > 0 && values[first] == values[first - 1] { continue; }
        let mut left = first + 1;
        let mut right = length - 1;
        while left < right {
            let sum = values[first] + values[left] + values[right];
            if sum < target {
                left += 1;
            } else if sum > target {
                right -= 1;
            } else {
                if write_output {
                    let offset = result_count * BYTES_PER_TRIPLET;
                    store_i32_le(output, offset, values[first]);
                    store_i32_le(output, offset + 4, values[left]);
                    store_i32_le(output, offset + 8, values[right]);
                }
                result_count += 1;
                left += 1;
                right -= 1;
                while left < right && values[left] == values[left - 1] { left += 1; }
                while left < right && values[right] == values[right + 1] { right -= 1; }
            }
        }
    }
    result_count
}

#[no_mangle]
pub extern "C" fn three_sum_problem(
    input: *const i64, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_ITEMS + 2 { return -1; }
    let packed = unsafe { std::slice::from_raw_parts(input, length) };
    let target = packed[0];
    let n_value = packed[1];
    if target < i32::MIN as i64 || target > i32::MAX as i64 || n_value < 0 || n_value > MAX_ITEMS as i64
        || length != n_value as usize + 2 { return -1; }
    let n = n_value as usize;
    let mut values = [0i64; MAX_ITEMS];
    for index in 0..n {
        let value = packed[index + 2];
        if !(-100_000..=100_000).contains(&value) { return -1; }
        values[index] = value;
    }
    heap_sort(&mut values, n);
    let maximum_bytes = if n < 2 { 0 } else { n * (n - 1) / 2 * BYTES_PER_TRIPLET };
    if output_capacity < maximum_bytes || output.is_null() {
        let needed = unsafe { enumerate_triplets(&values, n, target, std::ptr::null_mut(), false) } * BYTES_PER_TRIPLET;
        if output_capacity < needed || (needed != 0 && output.is_null()) { return -2; }
    }
    unsafe { enumerate_triplets(&values, n, target, output, !output.is_null()) as i64 }
}
