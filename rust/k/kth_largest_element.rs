/// Descending Lomuto quickselect with the final element as pivot.
const MAX_LENGTH: usize = 512;

#[no_mangle]
pub extern "C" fn kth_largest_element(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_LENGTH + 1 { return -1; }
    let packed = unsafe { std::slice::from_raw_parts(input, length) };
    let count = length - 1;
    if packed[0] < 1 || packed[0] > count as i64 { return -1; }
    let mut values = [0i32; MAX_LENGTH];
    for index in 0..count {
        let value = packed[index + 1];
        if value < i32::MIN as i64 || value > i32::MAX as i64 { return -1; }
        values[index] = value as i32;
    }
    let target = packed[0] as usize - 1;
    let mut low = 0;
    let mut high = count - 1;
    while low <= high {
        let pivot = values[high];
        let mut boundary = low;
        for scan in low..high {
            if values[scan] >= pivot {
                values.swap(boundary, scan);
                boundary += 1;
            }
        }
        values.swap(boundary, high);
        if boundary == target { return i64::from(values[boundary]); }
        if boundary > target { high = boundary - 1; }
        else { low = boundary + 1; }
    }
    -1
}
