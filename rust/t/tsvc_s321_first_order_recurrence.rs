const MAX_N: usize = 64;
const MAX_INPUT_LENGTH: usize = 1 + 2 * MAX_N;

fn bounded_value(value: i64) -> bool { (-1..=1).contains(&value) }

fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        unsafe { output.add(offset + byte).write((bits >> (8 * byte)) as u8); }
    }
}

#[no_mangle]
pub unsafe extern "C" fn tsvc_s321_first_order_recurrence(
    input: *const i64, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if input.is_null() || length < 3 || length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let n_raw = values[0];
    if n_raw < 1 || n_raw > MAX_N as i64 { return -1; }
    let n = n_raw as usize;
    if length != 1 + 2 * n { return -1; }

    let a_start = 1;
    let b_start = a_start + n;
    for i in 0..n {
        if !bounded_value(values[a_start + i]) || !bounded_value(values[b_start + i]) { return -1; }
    }
    if output.is_null() || output_capacity < 8 * n { return -2; }

    let mut a = [0i64; MAX_N];
    a[..n].copy_from_slice(&values[a_start..b_start]);
    for i in 1..n { a[i] += a[i - 1] * values[b_start + i]; }
    for i in 0..n { store_i64_le(output, 8 * i, a[i]); }
    n as i64
}
