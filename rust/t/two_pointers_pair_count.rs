const MAX_VALUES: usize = 256;
const MAX_INPUT_LENGTH: usize = MAX_VALUES + 2;

fn sift_down(values: &mut [i64; MAX_VALUES], mut root: usize, end: usize) {
    while root < end / 2 {
        let mut child = root * 2 + 1;
        if child + 1 < end && values[child] < values[child + 1] { child += 1; }
        if values[root] >= values[child] { break; }
        values.swap(root, child);
        root = child;
    }
}

fn heap_sort(values: &mut [i64; MAX_VALUES], length: usize) {
    for start in (0..length / 2).rev() { sift_down(values, start, length); }
    for end in (1..length).rev() {
        values.swap(0, end);
        sift_down(values, 0, end);
    }
}

#[no_mangle]
pub unsafe extern "C" fn two_pointers_pair_count(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_LENGTH { return -1; }
    let input = unsafe { std::slice::from_raw_parts(input, length) };
    let target = input[0];
    let count_value = input[1];
    if count_value < 0 || count_value > MAX_VALUES as i64 ||
        length != 2 + count_value as usize ||
        !(-2_000_000..=2_000_000).contains(&target) { return -1; }

    let count = count_value as usize;
    let mut values = [0i64; MAX_VALUES];
    for index in 0..count {
        let value = input[2 + index];
        if !(-1_000_000..=1_000_000).contains(&value) { return -1; }
        values[index] = value;
    }
    heap_sort(&mut values, count);
    if count < 2 { return 0; }
    for index in 1..count {
        if values[index - 1] == values[index] { return -1; }
    }

    let (mut left, mut right) = (0usize, count - 1);
    let mut pairs = 0i64;
    while left < right {
        let sum = values[left] + values[right];
        if sum < target {
            left += 1;
        } else if sum > target {
            right -= 1;
        } else {
            pairs += 1;
            left += 1;
        }
    }
    pairs
}

