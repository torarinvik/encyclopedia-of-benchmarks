const MAX_N: usize = 32;
const MAX_INPUT: usize = 33;
const CAPACITY: i64 = 10000;

unsafe fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { *output.add(offset + byte) = (bits >> (8 * byte)) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn harmonic_4_bin_packing(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT { return -1; }
    let n64 = *input;
    if n64 < 1 || n64 > MAX_N as i64 || length != 1 + n64 as usize { return -1; }
    let n = n64 as usize;
    for i in 0..n {
        let size = *input.add(1 + i);
        if !(1..=CAPACITY).contains(&size) { return -1; }
    }
    let output_bytes = 8 * (n + 1);
    if output.is_null() || capacity < output_bytes { return -2; }
    let mut current = [-1i64; 4];
    let mut remaining = [0i64; 4];
    let mut assignment = [0i64; MAX_N];
    let mut bins = 0i64;
    for i in 0..n {
        let size = *input.add(1 + i);
        let kind = if size * 2 > CAPACITY { 0 } else if size * 3 > CAPACITY { 1 }
            else if size * 4 > CAPACITY { 2 } else { 3 };
        if current[kind] < 0 || size > remaining[kind] {
            current[kind] = bins;
            bins += 1;
            remaining[kind] = CAPACITY;
        }
        assignment[i] = current[kind];
        remaining[kind] -= size;
    }
    store_i64_le(output, 0, bins);
    for i in 0..n { store_i64_le(output, 8 * (i + 1), assignment[i]); }
    output_bytes as i64
}
