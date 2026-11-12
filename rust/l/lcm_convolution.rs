const MAX_N: usize = 128;
const MAX_INPUT_LENGTH: usize = 1 + 2 * MAX_N + 1;
const MODULUS: i64 = 998_244_353;

unsafe fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        *output.add(offset + byte) = (bits >> (8 * byte)) as u8;
    }
}

fn multiple_zeta(values: &mut [i64; MAX_N + 1], n: usize) {
    for divisor in (1..=n).rev() {
        let mut multiple = 2 * divisor;
        while multiple <= n {
            values[multiple] += values[divisor];
            if values[multiple] >= MODULUS {
                values[multiple] -= MODULUS;
            }
            multiple += divisor;
        }
    }
}

fn multiple_mobius(values: &mut [i64; MAX_N + 1], n: usize) {
    for divisor in 1..=n {
        let mut multiple = 2 * divisor;
        while multiple <= n {
            values[multiple] -= values[divisor];
            if values[multiple] < 0 {
                values[multiple] += MODULUS;
            }
            multiple += divisor;
        }
    }
}

#[no_mangle]
pub unsafe extern "C" fn lcm_convolution(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 1 || length > MAX_INPUT_LENGTH {
        return -1;
    }
    let n_value = *input;
    if !(1..=MAX_N as i64).contains(&n_value) {
        return -1;
    }
    let n = n_value as usize;
    if length != 1 + 2 * n {
        return -1;
    }
    for index in 0..2 * n {
        let value = *input.add(1 + index);
        if !(0..MODULUS).contains(&value) {
            return -1;
        }
    }
    let output_bytes = 8 * n;
    if output.is_null() || capacity < output_bytes {
        return -2;
    }

    let mut a = [0i64; MAX_N + 1];
    let mut b = [0i64; MAX_N + 1];
    let mut c = [0i64; MAX_N + 1];
    for index in 1..=n {
        a[index] = *input.add(index);
        b[index] = *input.add(n + index);
    }
    multiple_zeta(&mut a, n);
    multiple_zeta(&mut b, n);
    for index in 1..=n {
        c[index] = (a[index] * b[index]) % MODULUS;
    }
    multiple_mobius(&mut c, n);
    for index in 1..=n {
        store_i64_le(output, 8 * (index - 1), c[index]);
    }
    output_bytes as i64
}
