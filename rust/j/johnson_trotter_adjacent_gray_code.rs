const MAX_N: usize = 3;
const MAX_OUTPUT_BYTES: usize = 144;

unsafe fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { *output.add(offset + byte) = (bits >> (8 * byte)) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn johnson_trotter_adjacent_gray_code(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length != 1 { return -1; }
    let raw_n = *input;
    if raw_n < 1 || raw_n > MAX_N as i64 { return -1; }
    let n = raw_n as usize;
    let mut permutation_count = 1usize;
    for value in 2..=n { permutation_count *= value; }
    let output_bytes = 8 * n * permutation_count;
    if output.is_null() || capacity < output_bytes { return -2; }
    let mut permutation = [0i64; MAX_N];
    let mut direction = [0i64; MAX_N + 1];
    for index in 0..n { permutation[index] = index as i64 + 1; direction[index + 1] = -1; }
    let mut staged = [0u8; MAX_OUTPUT_BYTES];
    let mut rows = 0usize;
    loop {
        for index in 0..n { store_i64_le(staged.as_mut_ptr(), 8 * (rows * n + index), permutation[index]); }
        rows += 1;
        let mut largest_mobile = 0i64;
        let mut mobile_position = n;
        for position in 0..n {
            let value = permutation[position];
            let neighbor = position as i64 + direction[value as usize];
            if neighbor >= 0 && neighbor < n as i64 && value > permutation[neighbor as usize] && value > largest_mobile {
                largest_mobile = value; mobile_position = position;
            }
        }
        if mobile_position == n { break; }
        let neighbor = (mobile_position as i64 + direction[largest_mobile as usize]) as usize;
        permutation.swap(mobile_position, neighbor);
        for value in (largest_mobile as usize + 1)..=n { direction[value] = -direction[value]; }
    }
    for byte in 0..output_bytes { *output.add(byte) = staged[byte]; }
    output_bytes as i64
}
