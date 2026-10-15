/// Sort a private copy, then scan neighbors for duplicates.
const MAX_VALUES: usize = 1024;

fn sift_down(values: &mut [i64; MAX_VALUES], mut root: usize, length: usize) {
    while root < length / 2 {
        let mut child = root * 2 + 1;
        if child + 1 < length && values[child] < values[child + 1] { child += 1; }
        if values[root] >= values[child] { break; }
        values.swap(root, child);
        root = child;
    }
}

/// Accepts signed 32-bit values; returns 1 if any repeat, 0 otherwise, -1 if invalid.
#[no_mangle]
pub extern "C" fn contains_duplicate(input: *const i64, length: usize) -> i64 {
    if length > MAX_VALUES || (length != 0 && input.is_null()) { return -1; }
    let mut values = [0i64; MAX_VALUES];
    for index in 0..length {
        let value = unsafe { *input.add(index) };
        if value < i32::MIN as i64 || value > i32::MAX as i64 { return -1; }
        values[index] = value;
    }
    for start in (0..length / 2).rev() { sift_down(&mut values, start, length); }
    for end in (2..=length).rev() {
        values.swap(0, end - 1);
        sift_down(&mut values, 0, end - 1);
    }
    for index in 1..length {
        if values[index - 1] == values[index] { return 1; }
    }
    0
}
