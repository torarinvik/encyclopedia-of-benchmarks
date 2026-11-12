use std::slice;

const N: usize = 24;
const MAX_REPETITIONS: usize = N * N / 4;
const INPUT_MAX: usize = N + 1;
const Z_MAX: usize = 2 * N + 1;

fn z_values(text: &[i64; Z_MAX], length: usize, z: &mut [usize; Z_MAX]) {
    z.fill(0);
    let (mut left, mut right) = (0usize, 0usize);
    let mut has_box = false;
    for i in 1..length {
        if has_box && i <= right {
            z[i] = (right - i + 1).min(z[i - left]);
        }
        while i + z[i] < length && text[z[i]] == text[i + z[i]] {
            z[i] += 1;
        }
        if !has_box || i + z[i] - 1 > right {
            left = i;
            right = i + z[i] - 1;
            has_box = true;
        }
    }
}

fn z_at(z: &[usize; Z_MAX], length: usize, index: usize) -> usize {
    if index < length { z[index] } else { 0 }
}

fn divide(
    symbols: &[i64; N],
    offset: usize,
    length: usize,
    marked: &mut [[bool; N + 1]; N],
) {
    if length <= 1 { return; }
    let left_size = length / 2;
    let right_size = length - left_size;
    let middle = offset + left_size;
    let mut buffer = [0i64; Z_MAX];
    let mut z = [0usize; Z_MAX];
    let mut before = [0usize; N];
    let mut after = [0usize; N];

    divide(symbols, offset, left_size, marked);
    divide(symbols, middle, right_size, marked);

    for i in 0..left_size { buffer[i] = symbols[middle - 1 - i]; }
    z_values(&buffer, left_size, &mut z);
    for center in 0..left_size {
        before[center] = z_at(&z, left_size, left_size - center);
    }

    let mut used = 0;
    for i in 0..right_size { buffer[used] = symbols[middle + i]; used += 1; }
    buffer[used] = -1;
    used += 1;
    for i in 0..left_size { buffer[used] = symbols[offset + i]; used += 1; }
    z_values(&buffer, used, &mut z);
    for center in 0..left_size {
        after[center] = z_at(&z, used, right_size + 1 + center);
    }

    for i in 0..left_size { buffer[i] = symbols[middle - 1 - i]; }
    used = left_size;
    buffer[used] = -1;
    used += 1;
    for i in 0..right_size { buffer[used] = symbols[offset + length - 1 - i]; used += 1; }
    z_values(&buffer, used, &mut z);
    for d in 0..right_size {
        before[left_size + d] = z_at(&z, used, left_size + 1 + right_size - 1 - d);
    }

    for i in 0..right_size { buffer[i] = symbols[middle + i]; }
    z_values(&buffer, right_size, &mut z);
    for d in 0..right_size { after[left_size + d] = z_at(&z, right_size, d + 1); }

    for center in 0..length {
        let left_biased = center < left_size;
        let half = if left_biased { left_size - center } else { center - left_size + 1 };
        if before[center] + after[center] < half { continue; }
        let low = 1usize.max(half.saturating_sub(after[center]));
        let high = half.min(before[center]);
        for first_half in low..=high {
            if left_biased && first_half == half { continue; }
            let start = if left_biased {
                center - first_half
            } else {
                center - half - first_half + 1
            };
            marked[offset + start][half] = true;
        }
    }
}

fn store(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        unsafe { output.add(offset + byte).write((bits >> (8 * byte)) as u8); }
    }
}

#[no_mangle]
pub unsafe extern "C" fn main_lorentz_tandem_repetitions(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 1 || length > INPUT_MAX { return -1; }
    let words = slice::from_raw_parts(input, length);
    let nr = words[0];
    if nr < 0 || nr > N as i64 || length != nr as usize + 1 { return -1; }
    let n = nr as usize;
    let mut symbols = [0i64; N];
    for i in 0..n {
        symbols[i] = words[i + 1];
        if !(0..=255).contains(&symbols[i]) { return -1; }
    }

    let mut marked = [[false; N + 1]; N];
    divide(&symbols, 0, n, &mut marked);
    let mut codes = [0i64; MAX_REPETITIONS];
    let mut count = 0usize;
    for start in 0..n {
        for half in 1..=n / 2 {
            if start + 2 * half <= n && marked[start][half] {
                codes[count] = (start * 32 + half) as i64;
                count += 1;
            }
        }
    }
    let required = 8 * (count + 1);
    if output.is_null() || capacity < required { return -2; }
    store(output, 0, count as i64);
    for i in 0..count { store(output, 8 * (i + 1), codes[i]); }
    required as i64
}
