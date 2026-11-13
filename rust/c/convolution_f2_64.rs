const MAX_N: usize = 8;
const MAX_M: usize = 8;
const MAX_PARSEABLE: usize = 19;

fn multiply_in_field(left: u64, right: u64) -> u64 {
    let mut result = 0u64;
    let mut shifted = left;
    let mut multiplier = right;
    for _ in 0..64 {
        if multiplier & 1 != 0 { result ^= shifted; }
        let carry = shifted >> 63;
        shifted <<= 1;
        if carry != 0 { shifted ^= 0x1b; }
        multiplier >>= 1;
    }
    result
}

fn solve(values: &[i64], output_capacity: usize) -> (i64, Vec<u8>) {
    if values.len() < 2 || values.len() > MAX_PARSEABLE { return (-1, Vec::new()); }
    if !(1..=MAX_N as i64).contains(&values[0])
            || !(1..=MAX_M as i64).contains(&values[1]) {
        return (-1, Vec::new());
    }
    let n = values[0] as usize;
    let m = values[1] as usize;
    if values.len() != 2 + n + m { return (-1, Vec::new()); }
    let count = n + m - 1;
    let needed = 8 * count;
    if output_capacity < needed { return (-2, Vec::new()); }

    let a: Vec<u64> = values[2..2 + n].iter().map(|&value| value as u64).collect();
    let b: Vec<u64> = values[2 + n..].iter().map(|&value| value as u64).collect();
    let mut product = vec![0u64; count];
    for (i, &left) in a.iter().enumerate() {
        for (j, &right) in b.iter().enumerate() {
            product[i + j] ^= multiply_in_field(left, right);
        }
    }
    let mut bytes = Vec::with_capacity(needed);
    for coefficient in product { bytes.extend_from_slice(&coefficient.to_le_bytes()); }
    (needed as i64, bytes)
}

#[no_mangle]
pub unsafe extern "C" fn convolution_f2_64(
    input: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_PARSEABLE { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if !(1..=MAX_N as i64).contains(&values[0])
            || !(1..=MAX_M as i64).contains(&values[1])
            || length != 2 + values[0] as usize + values[1] as usize {
        return -1;
    }
    let needed = 8 * (values[0] as usize + values[1] as usize - 1);
    if output.is_null() || output_capacity < needed { return -2; }
    let (status, bytes) = solve(values, output_capacity);
    if status < 0 { return status; }
    std::ptr::copy_nonoverlapping(bytes.as_ptr(), output, bytes.len());
    status
}
