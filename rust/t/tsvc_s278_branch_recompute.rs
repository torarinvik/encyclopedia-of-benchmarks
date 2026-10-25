const MAX_N: usize = 64;
const MAX_INPUT_LENGTH: usize = 2 + 5 * MAX_N;
const MAX_VALUE: i64 = 2;
const MAX_PASSES: i64 = 16;

fn bounded_value(value: i64) -> bool {
    (-MAX_VALUE..=MAX_VALUE).contains(&value)
}

fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        unsafe { output.add(offset + byte).write((bits >> (8 * byte)) as u8); }
    }
}

#[no_mangle]
pub unsafe extern "C" fn tsvc_s278_branch_recompute(
    input: *const i64, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if input.is_null() || length < 7 || length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let n_raw = values[0];
    let passes_raw = values[1];
    if n_raw < 1 || n_raw > MAX_N as i64 || passes_raw < 1 || passes_raw > MAX_PASSES { return -1; }
    let n = n_raw as usize;
    if length != 2 + 5 * n { return -1; }

    let a_start = 2;
    let b_start = a_start + n;
    let c_start = b_start + n;
    let d_start = c_start + n;
    let e_start = d_start + n;
    let mut a = [0i64; MAX_N];
    let mut b = [0i64; MAX_N];
    let mut c = [0i64; MAX_N];
    for i in 0..n {
        a[i] = values[a_start + i];
        b[i] = values[b_start + i];
        c[i] = values[c_start + i];
        if !bounded_value(a[i]) || !bounded_value(b[i]) || !bounded_value(c[i]) ||
            !bounded_value(values[d_start + i]) || !bounded_value(values[e_start + i]) { return -1; }
    }
    if output.is_null() || output_capacity < 24 * n { return -2; }

    for _pass in 0..passes_raw {
        for i in 0..n {
            let de = values[d_start + i] * values[e_start + i];
            if a[i] > 0 { c[i] = -c[i] + de; }
            else { b[i] = -b[i] + de; }
            a[i] = b[i] + c[i] * values[d_start + i];
        }
    }
    for i in 0..n {
        store_i64_le(output, 8 * i, a[i]);
        store_i64_le(output, 8 * (n + i), b[i]);
        store_i64_le(output, 8 * (2 * n + i), c[i]);
    }
    (3 * n) as i64
}
