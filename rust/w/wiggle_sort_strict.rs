const MAX_ARRAY_LENGTH: usize = 4096;

fn select_kth(values: &mut [i64; MAX_ARRAY_LENGTH], count: usize, target: usize) -> i64 {
    let mut low = 0isize;
    let mut high = count as isize - 1;
    while low < high {
        let mut left = low;
        let mut right = high;
        let pivot = values[((left + right + 1) / 2) as usize];
        while left <= right {
            while left <= right && values[left as usize] < pivot { left += 1; }
            while left <= right && values[right as usize] > pivot { right -= 1; }
            if left <= right {
                values.swap(left as usize, right as usize);
                left += 1;
                right -= 1;
            }
        }
        if target as isize <= right { high = right; }
        else if target as isize >= left { low = left; }
        else { break; }
    }
    values[target]
}

#[no_mangle]
pub extern "C" fn wiggle_sort_strict(input: *const i64, length: usize,
                                          output: *mut u8, output_capacity: usize) -> i64 {
    if length > MAX_ARRAY_LENGTH || (length != 0 && input.is_null()) { return -1; }
    let mut values = [0i64; MAX_ARRAY_LENGTH];

    for i in 0..length {
        let value = unsafe { *input.add(i) };
        if value < i32::MIN as i64 || value > i32::MAX as i64 { return -1; }
        values[i] = value;
    }
    let bytes = length * 4;
    if output_capacity < bytes || (bytes != 0 && output.is_null()) { return -2; }
    if length == 0 { return 0; }

    let median = select_kth(&mut values, length, length / 2);
    let mut median_count = 0usize;
    let mut smallest_value = values[0];
    for i in 0..length {
        if values[i] == median { median_count += 1; }
        if values[i] < smallest_value { smallest_value = values[i]; }
    }
    let maximum_medians = (length + 1) / 2;
    if median_count > maximum_medians
        || (length % 2 == 1 && median_count == maximum_medians && smallest_value != median) { return -1; }

    let mut i = 0isize;
    let mut j = 0isize;
    let mut k = length as isize - 1;
    let modulus = length as isize + 1 - (length % 2) as isize;
    while j <= k {
        let mapped_j = ((2 * j + 1) % modulus) as usize;
        if values[mapped_j] > median {
            let mapped_i = ((2 * i + 1) % modulus) as usize;
            values.swap(mapped_j, mapped_i);
            i += 1;
            j += 1;
        } else if values[mapped_j] < median {
            let mapped_k = ((2 * k + 1) % modulus) as usize;
            values.swap(mapped_j, mapped_k);
            k -= 1;
        } else {
            j += 1;
        }
    }
    for i in 0..length {
        let bits = values[i] as i32 as u32;
        for byte in 0..4 {
            unsafe { *output.add(i * 4 + byte) = (bits >> (byte * 8)) as u8; }
        }
    }
    length as i64
}
