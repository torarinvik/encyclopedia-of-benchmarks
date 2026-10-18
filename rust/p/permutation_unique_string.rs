const MAX_LENGTH: usize = 5;
const MAX_INPUT: usize = 7;
const MAX_OUTPUT: usize = 601;

#[no_mangle]
pub unsafe extern "C" fn permutation_unique_string(input: *const i64, input_length: usize,
    output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || input_length == 0 || input_length > MAX_INPUT { return -1; }
    let values = std::slice::from_raw_parts(input, input_length);
    if values[0] < 0 || values[0] > MAX_LENGTH as i64 || input_length != values[0] as usize + 1 { return -1; }
    let length = values[0] as usize;
    let mut current = [0u8; MAX_LENGTH];
    for i in 0..length {
        if !(32..=126).contains(&values[i + 1]) { return -1; }
        current[i] = values[i + 1] as u8;
    }
    current[..length].sort_unstable();
    let mut staged = [0u8; MAX_OUTPUT];
    let mut count = 0usize;
    loop {
        staged[1 + count * length..1 + count * length + length].copy_from_slice(&current[..length]);
        count += 1;
        if length < 2 { break; }
        let mut pivot = length - 1;
        while pivot > 0 && current[pivot - 1] >= current[pivot] { pivot -= 1; }
        if pivot == 0 { break; }
        let mut successor = length - 1;
        while current[successor] <= current[pivot - 1] { successor -= 1; }
        current.swap(pivot - 1, successor);
        current[pivot..length].reverse();
    }
    staged[0] = count as u8;
    let output_size = 1 + count * length;
    if output.is_null() || capacity < output_size { return -2; }
    std::ptr::copy_nonoverlapping(staged.as_ptr(), output, output_size);
    output_size as i64
}
