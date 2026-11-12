use std::slice;

const MAX_N: usize = 64;
const MAX_PARSEABLE: usize = 260;
const MAX_OUTPUT_WORDS: usize = 194;
const SCALE: i64 = 1_000_000;

fn trunc_div(numerator: i64, denominator: i64) -> i64 {
    if numerator < 0 { -((-numerator) / denominator) } else { numerator / denominator }
}

fn store_le(output: &mut [u8], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn splash2_water_nsquared(
    input_ptr: *const i64, length: usize, output_ptr: *mut u8, capacity: usize,
) -> i64 {
    if input_ptr.is_null() || length < 3 || length > MAX_PARSEABLE { return -1; }
    let input = slice::from_raw_parts(input_ptr, length);
    let n_raw = input[0];
    let grid = input[1];
    let radius = input[2];
    if n_raw < 0 || n_raw > MAX_N as i64 || grid < 1 || grid > 8 || radius < 1 || radius > 4 { return -1; }
    let n = n_raw as usize;
    if length != 3 + 4 * n { return -1; }
    let side = grid * radius;
    let radius2 = radius * radius;
    let (mut x, mut y, mut z, mut charge) = ([0i64; MAX_N], [0i64; MAX_N], [0i64; MAX_N], [0i64; MAX_N]);
    for i in 0..n {
        let at = 3 + 4 * i;
        x[i] = input[at]; y[i] = input[at + 1]; z[i] = input[at + 2]; charge[i] = input[at + 3];
        if x[i] < 0 || x[i] >= side || y[i] < 0 || y[i] >= side || z[i] < 0 || z[i] >= side || charge[i] < -4 || charge[i] > 4 { return -1; }
    }
    let mut force = [[0i64; 3]; MAX_N];
    let (mut energy, mut pairs) = (0i64, 0i64);
    for i in 0..n {
        for j in i + 1..n {
            let dx = x[j] - x[i]; let dy = y[j] - y[i]; let dz = z[j] - z[i];
            let r2 = dx * dx + dy * dy + dz * dz;
            if r2 >= radius2 { continue; }
            let product = charge[i] * charge[j];
            energy += trunc_div(product * (radius2 - r2) * SCALE, (1 + r2) * (1 + radius2));
            let denominator = (1 + r2) * (1 + r2);
            let pair_force = [
                trunc_div(-2 * product * dx * SCALE, denominator),
                trunc_div(-2 * product * dy * SCALE, denominator),
                trunc_div(-2 * product * dz * SCALE, denominator),
            ];
            for axis in 0..3 { force[i][axis] += pair_force[axis]; force[j][axis] -= pair_force[axis]; }
            pairs += 1;
        }
    }
    let words = 3 * n + 2;
    let bytes = 8 * words;
    if output_ptr.is_null() || capacity < bytes { return -2; }
    let mut result = [0i64; MAX_OUTPUT_WORDS];
    for i in 0..n { for axis in 0..3 { result[3 * i + axis] = force[i][axis]; } }
    result[3 * n] = energy; result[3 * n + 1] = pairs;
    let output = slice::from_raw_parts_mut(output_ptr, bytes);
    for word in 0..words { store_le(output, 8 * word, result[word]); }
    bytes as i64
}
