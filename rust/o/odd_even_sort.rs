/// Stable odd-even transposition sort for the shared sorting contract.
#[no_mangle]
pub extern "C" fn odd_even_sort(values: *mut i64, length: usize) {
    if length < 2 {
        return;
    }
    let values = unsafe { std::slice::from_raw_parts_mut(values, length) };
    let mut swapped = true;
    while swapped {
        swapped = false;
        for index in (0..(length - 1)).step_by(2) {
            if values[index] > values[index + 1] {
                values.swap(index, index + 1);
                swapped = true;
            }
        }
        for index in (1..(length - 1)).step_by(2) {
            if values[index] > values[index + 1] {
                values.swap(index, index + 1);
                swapped = true;
            }
        }
    }
}
