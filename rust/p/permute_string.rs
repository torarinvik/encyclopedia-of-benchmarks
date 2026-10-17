const MAX_N: usize = 7;
const MAX_INPUT_LENGTH: usize = 9;

fn factorial(value: usize) -> usize {
    (2..=value).product::<usize>().max(1)
}

fn unique_permutation_count(values: &[u8]) -> usize {
    if values.is_empty() { return 0; }
    let mut frequencies = [0usize; 128];
    for &value in values { frequencies[value as usize] += 1; }
    let mut count = factorial(values.len());
    for frequency in frequencies { count /= factorial(frequency); }
    count
}

fn next_permutation(values: &mut [u8]) -> bool {
    if values.len() < 2 { return false; }
    let mut pivot = values.len() - 1;
    while pivot > 0 && values[pivot - 1] >= values[pivot] { pivot -= 1; }
    if pivot == 0 { return false; }
    let mut successor = values.len() - 1;
    while values[successor] <= values[pivot - 1] { successor -= 1; }
    values.swap(pivot - 1, successor);
    values[pivot..].reverse();
    true
}

unsafe fn write_row(output: *mut u8, offset: usize, values: &[u8]) {
    for (column, &value) in values.iter().enumerate() {
        *output.add(offset + column) = value;
    }
}

#[no_mangle]
pub unsafe extern "C" fn permute_string(
    input: *const i64,
    input_length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length < 1 || input_length > MAX_INPUT_LENGTH { return -1; }
    let input = std::slice::from_raw_parts(input, input_length);
    if input[0] < 0 || input[0] > MAX_N as i64 { return -1; }
    let character_count = input[0] as usize;
    if input_length != character_count + 1 { return -1; }

    let mut values = [0u8; MAX_N];
    for index in 0..character_count {
        let value = input[index + 1];
        if !(0..=127).contains(&value) { return -1; }
        values[index] = value as u8;
    }
    values[..character_count].sort_unstable();

    let permutation_count = unique_permutation_count(&values[..character_count]);
    let output_bytes = permutation_count * character_count;
    if output.is_null() || output_capacity < output_bytes { return -2; }
    for row in 0..permutation_count {
        write_row(output, row * character_count, &values[..character_count]);
        if row + 1 < permutation_count {
            let _ = next_permutation(&mut values[..character_count]);
        }
    }
    output_bytes as i64
}
