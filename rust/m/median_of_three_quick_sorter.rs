fn median_of_three(a: i64, b: i64, c: i64) -> i64 {
    if a <= b {
        if b <= c { return b; }
        if a <= c { return c; }
        return a;
    }
    if b >= c { return b; }
    if a >= c { return c; }
    a
}

unsafe fn partition_range(values: *mut i64, left: usize, right: usize) -> usize {
    let middle = left + (right - left) / 2;
    let pivot = median_of_three(*values.add(left), *values.add(middle), *values.add(right));
    let mut nleft = left;
    let mut nright = right;
    loop {
        while *values.add(nleft) < pivot { nleft += 1; }
        while *values.add(nright) > pivot { nright -= 1; }
        if nleft >= nright { return nright; }
        std::ptr::swap(values.add(nleft), values.add(nright));
        nleft += 1;
        nright -= 1;
    }
}

unsafe fn sort_range(values: *mut i64, left: usize, right: usize) {
    if left >= right { return; }
    let pivot = partition_range(values, left, right);
    sort_range(values, left, pivot);
    sort_range(values, pivot + 1, right);
}

#[no_mangle]
pub unsafe extern "C" fn median_of_three_quick_sorter(values: *mut i64, length: usize) {
    if length > 1 && !values.is_null() { sort_range(values, 0, length - 1); }
}
