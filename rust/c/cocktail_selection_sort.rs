const MAX_VALUES: usize = 1024;

#[no_mangle]
pub unsafe extern "C" fn cocktail_selection_sort(values: *mut i64, length: usize) {
    if length > MAX_VALUES {
        return;
    }
    let mut low = 0;
    let mut high = length;
    while high - low > 1 {
        let mut minimum_index = low;
        let mut maximum_index = low;
        for index in low + 1..high {
            if *values.add(index) < *values.add(minimum_index) {
                minimum_index = index;
            }
            if *values.add(index) > *values.add(maximum_index) {
                maximum_index = index;
            }
        }
        std::ptr::swap(values.add(minimum_index), values.add(low));
        if maximum_index == low {
            maximum_index = minimum_index;
        }
        std::ptr::swap(values.add(maximum_index), values.add(high - 1));
        low += 1;
        high -= 1;
    }
}
