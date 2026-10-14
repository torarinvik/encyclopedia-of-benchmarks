/// Stable bottom-up merge sort using caller-provided scratch storage.
#[no_mangle]
pub extern "C" fn merge_sort(values: *mut i64, scratch: *mut i64, length: usize) {
    if length < 2 {
        return;
    }
    let values = unsafe { std::slice::from_raw_parts_mut(values, length) };
    let scratch = unsafe { std::slice::from_raw_parts_mut(scratch, length) };
    let mut width = 1usize;
    while width < length {
        let mut low = 0usize;
        while low < length {
            let middle = (low + width).min(length);
            let high = (middle + width).min(length);
            let (mut left, mut right, mut output) = (low, middle, low);
            while left < middle && right < high {
                if values[left] <= values[right] {
                    scratch[output] = values[left];
                    left += 1;
                } else {
                    scratch[output] = values[right];
                    right += 1;
                }
                output += 1;
            }
            while left < middle {
                scratch[output] = values[left];
                left += 1;
                output += 1;
            }
            while right < high {
                scratch[output] = values[right];
                right += 1;
                output += 1;
            }
            values[low..high].copy_from_slice(&scratch[low..high]);
            low = high;
        }
        if width > length / 2 {
            break;
        }
        width *= 2;
    }
}
