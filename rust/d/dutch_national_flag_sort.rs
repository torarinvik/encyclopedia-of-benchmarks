/// Dutch national flag sort for values restricted to 0, 1, and 2.
#[no_mangle]
pub extern "C" fn dutch_national_flag_sort(values: *mut i64, length: usize) {
    if length < 2 {
        return;
    }
    let values = unsafe { std::slice::from_raw_parts_mut(values, length) };
    let mut low = 0;
    let mut middle = 0;
    let mut high = length;
    while middle < high {
        if values[middle] == 0 {
            values.swap(low, middle);
            low += 1;
            middle += 1;
        } else if values[middle] == 1 {
            middle += 1;
        } else {
            high -= 1;
            values.swap(middle, high);
        }
    }
}
