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

/// In-place max-heap sort with a zero-based heap.
#[no_mangle]
pub extern "C" fn heap_sort(values: *mut i64, length: usize) {
    if length < 2 {
        return;
    }
    let values = unsafe { std::slice::from_raw_parts_mut(values, length) };
    for start in (0..(length / 2)).rev() {
        sift_down(values, start, length);
    }
    for end in (1..length).rev() {
        values.swap(0, end);
        sift_down(values, 0, end);
    }
}
