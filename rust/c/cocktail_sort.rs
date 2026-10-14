/// Stable bidirectional bubble sort for signed 64-bit values.
#[no_mangle]
pub extern "C" fn cocktail_sort(values: *mut i64, length: usize) {
    if length < 2 {
        return;
    }
    let values = unsafe { std::slice::from_raw_parts_mut(values, length) };
    let mut start = 0usize;
    let mut end = length;
    while start < end {
        let mut swapped = false;
        for index in start..(end - 1) {
            if values[index] > values[index + 1] {
                values.swap(index, index + 1);
                swapped = true;
            }
        }
        if !swapped {
            break;
        }
        end -= 1;
        swapped = false;
        let mut index = end;
        while index > start {
            if values[index - 1] > values[index] {
                values.swap(index - 1, index);
                swapped = true;
            }
            index -= 1;
        }
        start += 1;
        if !swapped {
            break;
        }
    }
}
