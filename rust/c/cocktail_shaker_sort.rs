/// Stable full-range bidirectional adjacent-swap sort.
#[no_mangle]
pub extern "C" fn cocktail_shaker_sort(values: *mut i64, length: usize) {
    if length < 2 {
        return;
    }
    let values = unsafe { std::slice::from_raw_parts_mut(values, length) };
    loop {
        let mut swapped = false;
        for index in 0..(length - 1) {
            if values[index] > values[index + 1] {
                values.swap(index, index + 1);
                swapped = true;
            }
        }
        if !swapped {
            break;
        }
        swapped = false;
        let mut index = length - 1;
        while index > 0 {
            if values[index - 1] > values[index] {
                values.swap(index - 1, index);
                swapped = true;
            }
            index -= 1;
        }
        if !swapped {
            break;
        }
    }
}
