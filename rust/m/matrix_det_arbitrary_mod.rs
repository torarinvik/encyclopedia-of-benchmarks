const MAX_N: usize = 8;
const MAX_INPUT_VALUES: usize = 2 + MAX_N * MAX_N + 1;
const MAX_MODULUS: i64 = 1_000_000_000;

unsafe fn store_i64_le(output: *mut u8, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        *output.add(byte) = (bits >> (8 * byte)) as u8;
    }
}

fn normalize(value: i64, modulus: i64) -> i64 {
    let residue = value % modulus;
    if residue < 0 { residue + modulus } else { residue }
}

#[no_mangle]
pub unsafe extern "C" fn matrix_det_arbitrary_mod(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_VALUES { return -1; }
    let n_value = *input;
    let modulus = *input.add(1);
    if !(0..=MAX_N as i64).contains(&n_value) || !(2..=MAX_MODULUS).contains(&modulus) {
        return -1;
    }
    let n = n_value as usize;
    if length != 2 + n * n { return -1; }

    let mut matrix = [[0i64; MAX_N]; MAX_N];
    for row in 0..n {
        for column in 0..n {
            let value = *input.add(2 + row * n + column);
            if value < 0 || value >= modulus { return -1; }
            matrix[row][column] = value;
        }
    }

    let mut determinant = 1i64;
    let mut sign = false;
    for column in 0..n {
        let mut pivot = column;
        while pivot < n && matrix[pivot][column] == 0 { pivot += 1; }
        if pivot == n {
            determinant = 0;
            break;
        }
        if pivot != column {
            matrix.swap(pivot, column);
            sign = !sign;
        }
        for row in column + 1..n {
            let mut left = matrix[column][column];
            let mut right = matrix[row][column];
            if right == 0 { continue; }
            let (mut a0, mut a1, mut b0, mut b1) = (1i64, 0i64, 0i64, 1i64);
            while left != 0 && right != 0 {
                if left < right {
                    let quotient = right / left;
                    right -= quotient * left;
                    b0 = normalize(b0 - a0 * quotient, modulus);
                    b1 = normalize(b1 - a1 * quotient, modulus);
                } else {
                    let quotient = left / right;
                    left -= quotient * right;
                    a0 = normalize(a0 - b0 * quotient, modulus);
                    a1 = normalize(a1 - b1 * quotient, modulus);
                }
            }
            for k in column..n {
                let old_top = matrix[column][k];
                let old_bottom = matrix[row][k];
                matrix[column][k] = normalize(old_top * a0 + old_bottom * a1, modulus);
                matrix[row][k] = normalize(old_top * b0 + old_bottom * b1, modulus);
            }
            if left == 0 {
                matrix.swap(column, row);
                sign = !sign;
            }
        }
        determinant = determinant * matrix[column][column] % modulus;
        if determinant == 0 { break; }
    }
    if sign && determinant != 0 { determinant = modulus - determinant; }
    if output.is_null() || capacity < 8 { return -2; }
    store_i64_le(output, determinant);
    8
}
