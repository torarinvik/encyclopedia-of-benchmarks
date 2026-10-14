/// Stable gnome sort for the shared mutable in-place sorting contract.
#[no_mangle]
pub extern "C" fn gnome_sort(values: *mut i64, length: usize) {
    if length < 2 {
        return;
    }
    let values = unsafe { std::slice::from_raw_parts_mut(values, length) };
    let mut position = 1usize;
    while position < length {
        if values[position] >= values[position - 1] {
            position += 1;
        } else {
            values.swap(position - 1, position);
            if position > 1 {
                position -= 1;
            } else {
                position = 1;
            }
        }
    }
}
