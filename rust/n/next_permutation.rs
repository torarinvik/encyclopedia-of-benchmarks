/// Replace a permutation by its lexicographic successor, wrapping to minimum.
const MAX_LENGTH: usize = 128;

unsafe fn store_i32_le(output: *mut u8, position: usize, value: i32) {
    for (byte, octet) in value.to_le_bytes().iter().enumerate() { *output.add(position + byte) = *octet; }
}

#[no_mangle]
pub extern "C" fn next_permutation(input: *const i64, length: usize,
    output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || length < 1 || length > MAX_LENGTH + 1 { return -1; }
    let packed = unsafe { std::slice::from_raw_parts(input, length) };
    let n_value = packed[0];
    if !(0..=MAX_LENGTH as i64).contains(&n_value) || length != n_value as usize + 1 { return -1; }
    let n = n_value as usize;
    let mut values = [0i32; MAX_LENGTH];
    for i in 0..n {
        if packed[i + 1] < i32::MIN as i64 || packed[i + 1] > i32::MAX as i64 { return -1; }
        values[i] = packed[i + 1] as i32;
    }
    let required = n * 4;
    if output_capacity < required || (required != 0 && output.is_null()) { return -2; }
    let pivot = (0..n.saturating_sub(1)).rev().find(|&i| values[i] < values[i + 1]);
    if let Some(pivot) = pivot {
        let successor = (pivot + 1..n).rev().find(|&i| values[i] > values[pivot]).unwrap();
        values.swap(pivot, successor);
        values[pivot + 1..n].reverse();
    } else {
        values[..n].reverse();
    }
    for i in 0..n { unsafe { store_i32_le(output, i * 4, values[i]); } }
    n as i64
}
