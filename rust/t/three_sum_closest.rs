const MAX_ITEMS: usize = 512;
const INVALID_RESULT: i64 = -9_000_000_000_000_000_000;

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
    for start in (0..length / 2).rev() { sift_down(values, start, length); }
    for end in (1..length).rev() {
        values.swap(0, end);
        sift_down(values, 0, end);
    }
}

fn absolute_difference(left: i64, right: i64) -> i64 { (left - right).abs() }

#[no_mangle]
pub extern "C" fn three_sum_closest(input: *const i64, length: usize) -> i64 {
    if length < 2 || length > MAX_ITEMS + 2 || input.is_null() { return INVALID_RESULT; }
    let target = unsafe { *input };
    let count_value = unsafe { *input.add(1) };
    if target < i32::MIN as i64 || target > i32::MAX as i64 || count_value < 3 || count_value > MAX_ITEMS as i64 {
        return INVALID_RESULT;
    }
    let count = count_value as usize;
    if length != count + 2 { return INVALID_RESULT; }
    let mut values = [0i64; MAX_ITEMS];
    for index in 0..count {
        let value = unsafe { *input.add(index + 2) };
        if value < i32::MIN as i64 || value > i32::MAX as i64 { return INVALID_RESULT; }
        values[index] = value;
    }
    heap_sort(&mut values[..count]);
    let mut best = values[0] + values[1] + values[2];
    let mut best_difference = absolute_difference(target, best);
    for first in 0..count - 2 {
        let mut left = first + 1;
        let mut right = count - 1;
        while left < right {
            let sum = values[first] + values[left] + values[right];
            let difference = absolute_difference(target, sum);
            if difference < best_difference || (difference == best_difference && sum < best) {
                best = sum;
                best_difference = difference;
            }
            if sum < target { left += 1; }
            else if sum > target { right -= 1; }
            else { return sum; }
        }
    }
    best
}
