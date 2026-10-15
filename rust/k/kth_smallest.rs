/// One-based quickselect using the pinned last-element partition.
const MAX_LENGTH: usize = 256;
const INVALID_RESULT: i64 = i64::MIN;

fn partition_values(values: &mut [i32; MAX_LENGTH], low: usize, high: usize) -> usize {
    let pivot = high;
    let mut i = low;
    let mut j = high - 1;
    loop {
        while values[i] < values[pivot] { i += 1; }
        while j > 0 && values[j] > values[pivot] { j -= 1; }
        if j == 0 || i >= j { break; }
        if values[i] == values[j] {
            i += 1;
            j -= 1;
        } else {
            values.swap(i, j);
        }
    }
    values.swap(i, pivot);
    i
}

#[no_mangle]
pub extern "C" fn kth_smallest(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 3 || length > MAX_LENGTH + 2 { return INVALID_RESULT; }
    let packed = unsafe { std::slice::from_raw_parts(input, length) };
    let n_value = packed[0];
    let k_value = packed[1];
    if n_value < 1 || n_value > MAX_LENGTH as i64 || k_value < 1 || k_value > n_value || length != n_value as usize + 2 {
        return INVALID_RESULT;
    }
    let n = n_value as usize;
    let mut values = [0i32; MAX_LENGTH];
    for index in 0..n {
        let value = packed[index + 2];
        if value < i32::MIN as i64 || value > i32::MAX as i64 { return INVALID_RESULT; }
        values[index] = value as i32;
    }

    let mut low = 0;
    let mut high = n - 1;
    let mut k = k_value as usize;
    while low < high {
        let pivot = partition_values(&mut values, low, high);
        let pivot_rank = pivot - low + 1;
        if k == pivot_rank { return i64::from(values[pivot]); }
        if k < pivot_rank {
            high = pivot - 1;
        } else {
            low = pivot + 1;
            k -= pivot_rank;
        }
    }
    i64::from(values[low])
}
