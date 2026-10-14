/// Stable bubble sort for the shared mutable in-place sorting contract.
#[no_mangle]
pub extern "C" fn bubble_sort(values: *mut i64, length: usize) {
    if length < 2 {
        return;
    }
    let values = unsafe { std::slice::from_raw_parts_mut(values, length) };
    for end in (2..=length).rev() {
        let mut swapped = false;
        for index in 0..(end - 1) {
            if values[index] > values[index + 1] {
                values.swap(index, index + 1);
                swapped = true;
            }
        }
        if !swapped {
            break;
        }
    }
}
