const MAX_N: usize = 7;
const MAX_INPUT_WORDS: usize = 52;

fn residue(value: i64, modulus: i64) -> i64 {
    let result = value % modulus;
    if result < 0 { result + modulus } else { result }
}

fn negative_residue(value: i64, modulus: i64) -> i64 {
    if value == 0 { 0 } else { modulus - value }
}

unsafe fn store_i64_le(output: *mut u8, word: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        output.add(word * 8 + byte).write((bits >> (byte * 8)) as u8);
    }
}

#[no_mangle]
pub unsafe extern "C" fn berkowitz_characteristic_polynomial(
    input: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || !(3..=MAX_INPUT_WORDS).contains(&length) {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, length);
    let n64 = values[0];
    let modulus = values[1];
    if !(1..=MAX_N as i64).contains(&n64) || !(2..=1_000_000_000).contains(&modulus) {
        return -1;
    }
    let n = n64 as usize;
    if length != 2 + n * n {
        return -1;
    }
    let mut matrix = [0i64; MAX_N * MAX_N];
    for i in 0..n * n {
        let entry = values[i + 2];
        if !(-1_000_000..=1_000_000).contains(&entry) {
            return -1;
        }
        matrix[i] = residue(entry, modulus);
    }
    let output_bytes = (n + 1) * 8;
    if output.is_null() || output_capacity < output_bytes {
        return -2;
    }

    let mut coefficients = [0i64; MAX_N + 1];
    let mut current = [0i64; MAX_N + 1];
    let mut toeplitz = [0i64; MAX_N + 1];
    let mut vector = [0i64; MAX_N];
    let mut next_vector = [0i64; MAX_N];
    coefficients[0] = 1;
    for size in 1..=n {
        let start = n - size;
        let block = size - 1;
        toeplitz.fill(0);
        toeplitz[0] = 1;
        toeplitz[1] = negative_residue(matrix[start * n + start], modulus);
        for row in 0..block {
            vector[row] = matrix[(start + 1 + row) * n + start];
        }
        for power in 0..block {
            let mut dot = 0i64;
            for col in 0..block {
                dot = (dot + matrix[start * n + start + 1 + col] * vector[col]) % modulus;
            }
            toeplitz[power + 2] = negative_residue(dot, modulus);
            for row in 0..block {
                let mut value = 0i64;
                for col in 0..block {
                    value = (value + matrix[(start + 1 + row) * n + start + 1 + col]
                        * vector[col]) % modulus;
                }
                next_vector[row] = value;
            }
            for row in 0..block {
                vector[row] = next_vector[row];
            }
        }
        for i in 0..=size {
            let mut value = 0i64;
            let last_child = if i < size - 1 { i } else { size - 1 };
            for j in 0..=last_child {
                value = (value + toeplitz[i - j] * coefficients[j]) % modulus;
            }
            current[i] = value;
        }
        for i in 0..=size {
            coefficients[i] = current[i];
        }
    }
    for i in 0..=n {
        store_i64_le(output, i, coefficients[i]);
    }
    output_bytes as i64
}
