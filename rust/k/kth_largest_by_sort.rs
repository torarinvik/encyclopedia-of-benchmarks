/// Sort a local copy with portable heapsort, then index from the end.
const MAX_LENGTH: usize = 512;

fn sift_down(values: &mut [i32; MAX_LENGTH], root_start: usize, end: usize) {
    let mut root = root_start;
    while root < end / 2 {
        let mut child = root * 2 + 1;
        if child + 1 < end && values[child] < values[child + 1] { child += 1; }
        if values[root] >= values[child] { break; }
        values.swap(root, child);
        root = child;
    }
}

#[no_mangle]
pub extern "C" fn kth_largest_by_sort(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_LENGTH + 1 { return -1; }
    let packed = unsafe { std::slice::from_raw_parts(input, length) };
    let count = length - 1;
    if packed[0] < 1 || packed[0] > count as i64 { return -1; }
    let mut values = [0i32; MAX_LENGTH];
    for index in 0..count {
        let value = packed[index + 1];
        if value < i32::MIN as i64 || value > i32::MAX as i64 { return -1; }
        values[index] = value as i32;
    }
    for start in (0..count / 2).rev() { sift_down(&mut values, start, count); }
    let mut end = count;
    while end > 1 {
        values.swap(0, end - 1);
        end -= 1;
        sift_down(&mut values, 0, end);
    }
    i64::from(values[count - packed[0] as usize])
}
