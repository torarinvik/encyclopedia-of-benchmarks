const MAX_VALUES: usize = 1024;

unsafe fn sift_up(values: *mut i64, index_value: usize) {
    let mut index = index_value;
    while index > 0 {
        let parent = (index - 1) / 2;
        if *values.add(parent) >= *values.add(index) { break }
        std::ptr::swap(values.add(parent), values.add(index));
        index = parent;
    }
}

unsafe fn sift_down(values: *mut i64, size: usize) {
    let mut root = 0;
    while root < size / 2 {
        let left = root * 2 + 1;
        let mut largest = left;
        let right = left + 1;
        if right < size && *values.add(right) > *values.add(left) { largest = right }
        if *values.add(root) >= *values.add(largest) { break }
        std::ptr::swap(values.add(root), values.add(largest));
        root = largest;
    }
}

#[no_mangle]
pub unsafe extern "C" fn heap_sort_2(values: *mut i64, length: usize) {
    if length > MAX_VALUES { return }
    for index in 0..length { sift_up(values, index) }
    for size in (2..=length).rev() {
        std::ptr::swap(values, values.add(size - 1));
        sift_down(values, size - 1);
    }
}
