const MAX_VALUES: usize = 256;

unsafe fn bubble_sort_recursive_impl(values: *mut i64, length: usize) {
    if length <= 1 {
        return;
    }
    let mut swapped = false;
    for index in 0..length - 1 {
        if *values.add(index) > *values.add(index + 1) {
            std::ptr::swap(values.add(index), values.add(index + 1));
            swapped = true;
        }
    }
    if swapped {
        bubble_sort_recursive_impl(values, length - 1);
    }
}

#[no_mangle]
pub unsafe extern "C" fn bubble_sort_recursive(values: *mut i64, length: usize) {
    if length <= MAX_VALUES {
        bubble_sort_recursive_impl(values, length);
    }
}
