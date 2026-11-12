const MAX_N: usize = 10;
const MAX_INPUT_VALUES: usize = 3;
const OUTPUT_BYTES: usize = 8;

fn cycle_count(n: usize, shift: usize, reflection: bool) -> usize {
    let mut seen = [false; MAX_N];
    let mut cycles = 0;
    for start in 0..n {
        if seen[start] {
            continue;
        }
        cycles += 1;
        let mut position = start;
        while !seen[position] {
            seen[position] = true;
            position = if reflection {
                (shift + n - position) % n
            } else {
                (position + shift) % n
            };
        }
    }
    cycles
}

fn fixed_colorings(n: usize, shift: usize, reflection: bool, colors: i64) -> i64 {
    let cycles = cycle_count(n, shift, reflection);
    let mut result = 1_i64;
    for _ in 0..cycles {
        result *= colors;
    }
    result
}

unsafe fn store_i64_le(output: *mut u8, value: i64) {
    let bits = value as u64;
    for byte in 0..OUTPUT_BYTES {
        *output.add(byte) = (bits >> (8 * byte)) as u8;
    }
}

#[no_mangle]
pub unsafe extern "C" fn burnside_bracelets(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || !(1..=MAX_INPUT_VALUES).contains(&length) {
        return -1;
    }
    if length != 2 {
        return -1;
    }
    let n_value = *input;
    let colors = *input.add(1);
    if !(1..=MAX_N as i64).contains(&n_value) || !(0..=3).contains(&colors) {
        return -1;
    }
    let n = n_value as usize;

    let mut fixed_sum = 0_i64;
    for shift in 0..n {
        fixed_sum += fixed_colorings(n, shift, false, colors);
        fixed_sum += fixed_colorings(n, shift, true, colors);
    }
    let answer = fixed_sum / (2 * n) as i64;
    if output.is_null() || capacity < OUTPUT_BYTES {
        return -2;
    }
    store_i64_le(output, answer);
    OUTPUT_BYTES as i64
}
