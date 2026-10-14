/// SlowSort over an inclusive interval.
unsafe fn slow_sort_range(values: *mut i64, first: usize, last: usize) {
    if first >= last { return; }
    let middle = first + (last - first) / 2;
    slow_sort_range(values, first, middle);
    slow_sort_range(values, middle + 1, last);
    if *values.add(last) < *values.add(middle) {
        let temporary = *values.add(last);
        *values.add(last) = *values.add(middle);
        *values.add(middle) = temporary;
    }
    slow_sort_range(values, first, last - 1);
}

#[no_mangle]
pub unsafe extern "C" fn slow_sort(values: *mut i64, length: usize) {
    if length > 1 { slow_sort_range(values, 0, length - 1); }
}
