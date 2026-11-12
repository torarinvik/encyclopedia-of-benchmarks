const MODULUS: i64 = 998_244_353;
const MAX_N: usize = 8;
const MAX_INPUT_VALUES: usize = 1 + MAX_N * MAX_N + 1;

fn normalize(value: i64) -> i64 {
    let value = value % MODULUS;
    if value < 0 { value + MODULUS } else { value }
}

fn multiply(left: i64, right: i64) -> i64 {
    (left * right) % MODULUS
}

fn power(mut base: i64, mut exponent: i64) -> i64 {
    let mut result = 1;
    while exponent > 0 {
        if exponent & 1 != 0 {
            result = multiply(result, base);
        }
        base = multiply(base, base);
        exponent >>= 1;
    }
    result
}

unsafe fn store_i64_le(output: *mut u8, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        *output.add(byte) = (bits >> (8 * byte)) as u8;
    }
}

#[no_mangle]
pub unsafe extern "C" fn characteristic_polynomial(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 1 || length > MAX_INPUT_VALUES {
        return -1;
    }
    let n_value = *input;
    if !(0..=MAX_N as i64).contains(&n_value) {
        return -1;
    }
    let n = n_value as usize;
    if length != 1 + n * n {
        return -1;
    }

    let mut matrix = [[0i64; MAX_N]; MAX_N];
    for row in 0..n {
        for column in 0..n {
            let value = *input.add(1 + row * n + column);
            if !(0..MODULUS).contains(&value) {
                return -1;
            }
            matrix[row][column] = value;
        }
    }

    for column in 0..n.saturating_sub(2) {
        let mut pivot = column + 1;
        while pivot < n && matrix[pivot][column] == 0 {
            pivot += 1;
        }
        if pivot == n {
            continue;
        }
        if pivot != column + 1 {
            matrix.swap(column + 1, pivot);
            for row in 0..n {
                let value = matrix[row][column + 1];
                matrix[row][column + 1] = matrix[row][pivot];
                matrix[row][pivot] = value;
            }
        }
        let inverse = power(matrix[column + 1][column], MODULUS - 2);
        for row in column + 2..n {
            if matrix[row][column] == 0 {
                continue;
            }
            let factor = multiply(matrix[row][column], inverse);
            for k in 0..n {
                matrix[row][k] = normalize(
                    matrix[row][k] - multiply(factor, matrix[column + 1][k]),
                );
            }
            for k in 0..n {
                matrix[k][column + 1] = normalize(
                    matrix[k][column + 1] + multiply(factor, matrix[k][row]),
                );
            }
        }
    }

    let mut coefficients = [[0i64; MAX_N + 1]; MAX_N + 1];
    coefficients[0][0] = 1;
    for size in 1..=n {
        for degree in 0..=size {
            let mut value = if degree == 0 {
                0
            } else {
                coefficients[size - 1][degree - 1]
            };
            if degree < size {
                value -= multiply(
                    matrix[size - 1][size - 1],
                    coefficients[size - 1][degree],
                );
            }
            coefficients[size][degree] = normalize(value);
        }
        let mut subdiagonal_product = 1;
        for start in (0..size.saturating_sub(1)).rev() {
            subdiagonal_product = multiply(
                subdiagonal_product,
                matrix[start + 1][start],
            );
            let term = multiply(subdiagonal_product, matrix[start][size - 1]);
            for degree in 0..=start {
                coefficients[size][degree] = normalize(
                    coefficients[size][degree]
                        - multiply(term, coefficients[start][degree]),
                );
            }
        }
    }

    let output_bytes = 8 * (n + 1);
    if output.is_null() || capacity < output_bytes {
        return -2;
    }
    for degree in 0..=n {
        store_i64_le(output.add(8 * degree), coefficients[n][degree]);
    }
    output_bytes as i64
}
