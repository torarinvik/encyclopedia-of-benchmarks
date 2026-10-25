// Clean-room port of TSVC s281; see the package README for provenance and rights.

const MAX_N: i64 = 16;
const MAX_INPUT_LENGTH: usize = 50;

fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        unsafe { output.add(offset + byte).write((bits >> (8 * byte)) as u8); }
    }
}

#[no_mangle]
pub unsafe extern "C" fn tsvc_s281_reverse_coupled_update(
    input: *const i64,
    input_length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length < 5 || input_length > MAX_INPUT_LENGTH { return -1; }
    let values = core::slice::from_raw_parts(input, input_length);
    if values[0] < 1 || values[0] > MAX_N || values[1] < 1 || values[1] > 8 { return -1; }
    let n = values[0] as usize;
    let passes = values[1] as usize;
    if input_length != 2 + 3 * n { return -1; }

    let mut a = [0.0_f64; MAX_N as usize];
    let mut b = [0.0_f64; MAX_N as usize];
    let mut c = [0.0_f64; MAX_N as usize];
    for i in 0..n {
        let av = values[2 + i];
        let bv = values[2 + n + i];
        let cv = values[2 + 2 * n + i];
        if !(-2..=2).contains(&av) || !(-2..=2).contains(&bv) || !(-1..=1).contains(&cv) { return -1; }
        a[i] = av as f64;
        b[i] = bv as f64;
        c[i] = cv as f64;
    }

    let output_bytes = 16 * n;
    if output.is_null() || output_capacity < output_bytes { return -2; }
    for _ in 0..passes {
        for i in 0..n {
            let x = a[n - i - 1] + b[i] * c[i];
            a[i] = x - 1.0;
            b[i] = x;
        }
    }
    for i in 0..n {
        store_i64_le(output, 8 * i, a[i] as i64);
        store_i64_le(output, 8 * (n + i), b[i] as i64);
    }
    output_bytes as i64
}
