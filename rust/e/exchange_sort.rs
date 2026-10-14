/// In-place exchange sort for the shared sorting contract.
#[no_mangle]
pub extern "C" fn exchange_sort(values: *mut i64, length: usize) {
    if length < 2 {
        return;
    }
    let values = unsafe { std::slice::from_raw_parts_mut(values, length) };
    let last = length - 1;
    for first in 0..last {
        for other in first + 1..length {
            if values[other] < values[first] {
                values.swap(first, other);
            }
        }
    }
}
