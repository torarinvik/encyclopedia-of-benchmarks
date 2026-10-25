const MAX_N: usize = 16;
const MAX_TRIANGLE: usize = MAX_N * (MAX_N + 1) / 2;
const MAX_INPUT_LENGTH: usize = 2 + MAX_TRIANGLE + MAX_N * MAX_N;
const MAX_VALUE: i64 = 1_000_000;
const MAX_ROUNDS: usize = 32;

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
pub unsafe extern "C" fn tsvc_s141_packed_symmetric_update(
    input: *const i64, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if input.is_null() || length < 4 || length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let n_raw = values[0];
    let rounds_raw = values[1];
    if n_raw < 1 || n_raw > MAX_N as i64 || rounds_raw < 1 || rounds_raw > MAX_ROUNDS as i64 { return -1; }
    let n = n_raw as usize;
    let rounds = rounds_raw as usize;
    let triangle = n * (n + 1) / 2;
    let matrix_start = 2 + triangle;
    if length != matrix_start + n * n { return -1; }

    let mut packed = [0i64; MAX_TRIANGLE];
    for p in 0..triangle {
        packed[p] = values[2 + p];
        if !bounded_value(packed[p]) { return -1; }
    }
    for p in 0..n * n {
        if !bounded_value(values[matrix_start + p]) { return -1; }
    }
    if output.is_null() || output_capacity < 8 * triangle { return -2; }

    for _round in 0..rounds {
        for i in 0..n {
            for j in i..n {
                let k = j * (j + 1) / 2 + i;
                packed[k] += values[matrix_start + j * n + i];
            }
        }
    }
    for p in 0..triangle { store_i64_le(output, 8 * p, packed[p]); }
    triangle as i64
}
