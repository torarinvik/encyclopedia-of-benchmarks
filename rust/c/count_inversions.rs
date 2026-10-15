/// Count strict inversions with bottom-up merge sort.
#[no_mangle]
pub extern "C" fn count_inversions(values: *const i64, length: usize) -> i64 {
    const MAX_LENGTH: usize = 4096;
    if length > MAX_LENGTH || (length != 0 && values.is_null()) {
        return -1;
    }
    if length < 2 {
        return 0;
    }

    let values = unsafe { std::slice::from_raw_parts(values, length) };
    let mut source = [0i64; MAX_LENGTH];
    let mut scratch = [0i64; MAX_LENGTH];
    source[..length].copy_from_slice(values);

    let mut inversions = 0i64;
    let mut width = 1;
    while width < length {
        let mut low = 0;
        while low < length {
            let middle = (low + width).min(length);
            let high = (middle + width).min(length);
            let (mut left, mut right, mut output) = (low, middle, low);
            while left < middle && right < high {
                if source[left] <= source[right] {
                    scratch[output] = source[left];
                    left += 1;
                } else {
                    scratch[output] = source[right];
                    right += 1;
                    inversions += (middle - left) as i64;
                }
                output += 1;
            }
            while left < middle {
                scratch[output] = source[left];
                left += 1;
                output += 1;
            }
            while right < high {
                scratch[output] = source[right];
                right += 1;
                output += 1;
            }
            low = high;
        }
        source[..length].copy_from_slice(&scratch[..length]);
        width *= 2;
    }
    inversions
}
